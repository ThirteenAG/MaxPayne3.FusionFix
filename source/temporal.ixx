module;

#include <common.hxx>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <wrl/client.h>
#include <atomic>
#include <vector>
#include <unordered_map>
#include <span>
#include <bit>
#include <cstdio>
#include <cstdarg>

export module temporal;

import common;
import settings;
import postfxcommon;
import hdr;

namespace
{
    using Microsoft::WRL::ComPtr;

    void Log([[maybe_unused]] const char* format, ...)
    {
#ifdef _DEBUG
        static std::mutex mutex;
        std::lock_guard lock(mutex);
        FILE* file{};
        auto path = GetThisModulePath() / L"MaxPayne3.FusionFix.Motion.log";
        if (_wfopen_s(&file, path.c_str(), L"a") || !file)
            return;
        va_list arguments;
        va_start(arguments, format);
        vfprintf(file, format, arguments);
        va_end(arguments);
        fputc('\n', file);
        fclose(file);
#endif
    }

    std::vector<void*> Entities;
    std::atomic<bool> Enabled{};
    std::atomic<uint64_t> ResetVersion{};
    uint64_t AppliedReset{};
    bool BuildingScene{};
    uint64_t Frame{ 1 };
    bool Collecting{};
    float PixelParameters[4]{};
    int (__cdecl* QueueCallbackData)(void*, void* const*){};

    int __cdecl BeginEntity(void* entity)
    {
        Entities.push_back(entity);
        return 0;
    }

    int __cdecl EndEntity(void*)
    {
        if (!Entities.empty())
            Entities.pop_back();
        return 0;
    }

    void QueueEntity(void* entity, bool begin)
    {
        QueueCallbackData(reinterpret_cast<void*>(begin ? BeginEntity : EndEntity), &entity);
    }

    template<size_t Index>
    struct EntityDraw
    {
        static inline SafetyHookInline Hook;

        static int __fastcall Draw(void* entity, void*, int pass, int flags)
        {
            if (!Enabled || !BuildingScene)
                return Hook.unsafe_thiscall<int>(entity, pass, flags);
            QueueEntity(entity, true);
            auto result = Hook.unsafe_thiscall<int>(entity, pass, flags);
            QueueEntity(entity, false);
            return result;
        }
    };

    struct ConstantField
    {
        uint32_t Buffer;
        uint32_t Source;
        uint32_t Destination;
        uint32_t Size;
    };

    struct PreviousConstants
    {
        uint32_t Slot{};
        uint32_t Size{};
        std::vector<ConstantField> Fields;
        std::vector<std::pair<uint32_t, uint32_t>> Resources;
        uint64_t Generation{};
    };

    std::unordered_map<ID3D11VertexShader*, PreviousConstants> VertexConstants;
    std::unordered_map<ID3D11PixelShader*, uint32_t> PixelConstants;
    std::unordered_map<ID3D11DomainShader*, PreviousConstants> DomainConstants;
    std::mutex ShaderMutex;
    std::atomic<uint64_t> ShaderGeneration{};
    std::atomic<bool> ShadersReady11{}, TargetReady{};
    ComPtr<ID3D11Texture2D> MotionTexture11;
    uint64_t MotionFrame11{};
    void** GBufferTarget{};
    void** SceneTarget{};
    void (*ResolveScene)(){};
    void (*SceneStarted)(){};
    uint64_t ResolvedSceneFrame{};
    ComPtr<ID3D11RenderTargetView> MotionTarget11;
    struct MotionBlend11
    {
        ComPtr<ID3D11BlendState> Original, Motion;
    };
    std::map<ID3D11BlendState*, MotionBlend11> MotionBlends11;

    IUnknown* NativeGBuffer()
    {
        return GBufferTarget && *GBufferTarget ? *reinterpret_cast<IUnknown**>(static_cast<uint8_t*>(*GBufferTarget) + 0x38) : nullptr;
    }

    ID3D11Texture2D* NativeScene()
    {
        return SceneTarget && *SceneTarget ? *reinterpret_cast<ID3D11Texture2D**>(static_cast<uint8_t*>(*SceneTarget) + 0x38) : nullptr;
    }

    // The game writes mapped constants with aligned SSE stores
    template<typename T>
    struct Aligned16
    {
        using value_type = T;
        Aligned16() = default;
        template<typename U> Aligned16(const Aligned16<U>&) {}
        T* allocate(size_t count) { return static_cast<T*>(::operator new(count * sizeof(T), std::align_val_t{ 16 })); }
        void deallocate(T* pointer, size_t) { ::operator delete(pointer, std::align_val_t{ 16 }); }
        template<typename U> bool operator==(const Aligned16<U>&) const { return true; }
    };

    struct BufferContents
    {
        std::vector<uint8_t, Aligned16<uint8_t>> Bytes;
        void* Mapped{};
        bool Redirected{};
        bool Valid{};
    };

    std::unordered_map<ID3D11Resource*, BufferContents> Buffers;
    std::mutex BufferMutex;
    HRESULT (STDMETHODCALLTYPE* CreateBuffer)(ID3D11Device*, const D3D11_BUFFER_DESC*, const D3D11_SUBRESOURCE_DATA*, ID3D11Buffer**){};
    HRESULT (STDMETHODCALLTYPE* Map)(ID3D11DeviceContext*, ID3D11Resource*, UINT, D3D11_MAP, UINT, D3D11_MAPPED_SUBRESOURCE*){};
    void (STDMETHODCALLTYPE* Unmap)(ID3D11DeviceContext*, ID3D11Resource*, UINT){};
    void (STDMETHODCALLTYPE* UpdateSubresource)(ID3D11DeviceContext*, ID3D11Resource*, UINT, const D3D11_BOX*, const void*, UINT, UINT){};
    void (STDMETHODCALLTYPE* CopyResource)(ID3D11DeviceContext*, ID3D11Resource*, ID3D11Resource*){};
    void (STDMETHODCALLTYPE* CopySubresourceRegion)(ID3D11DeviceContext*, ID3D11Resource*, UINT, UINT, UINT, UINT, ID3D11Resource*, UINT, const D3D11_BOX*){};

    HRESULT STDMETHODCALLTYPE NewBuffer(ID3D11Device* device, const D3D11_BUFFER_DESC* description,
        const D3D11_SUBRESOURCE_DATA* data, ID3D11Buffer** output)
    {
        auto result = CreateBuffer(device, description, data, output);
        if (SUCCEEDED(result) && output && *output)
        {
            std::lock_guard lock(BufferMutex);
            Buffers.erase(*output);
            if (description->BindFlags & D3D11_BIND_CONSTANT_BUFFER)
            {
                auto& contents = Buffers[*output];
                contents.Bytes.resize(description->ByteWidth);
                if (data && data->pSysMem)
                {
                    std::memcpy(contents.Bytes.data(), data->pSysMem, contents.Bytes.size());
                    contents.Valid = true;
                }
            }
        }
        return result;
    }

    HRESULT STDMETHODCALLTYPE MapBuffer(ID3D11DeviceContext* context, ID3D11Resource* resource,
        UINT subresource, D3D11_MAP type, UINT flags, D3D11_MAPPED_SUBRESOURCE* mapped)
    {
        auto result = Map(context, resource, subresource, type, flags, mapped);
        if (SUCCEEDED(result) && type != D3D11_MAP_READ)
        {
            std::lock_guard lock(BufferMutex);
            if (auto found = Buffers.find(resource); found != Buffers.end())
            {
                // Discarded contents are written to the copy and uploaded at Unmap: reading the mapped
                // memory back is uncached and slow
                auto& contents = found->second;
                contents.Mapped = mapped->pData;
                contents.Redirected = type == D3D11_MAP_WRITE_DISCARD;
                if (contents.Redirected)
                    mapped->pData = contents.Bytes.data();
            }
        }
        return result;
    }

    void STDMETHODCALLTYPE UnmapBuffer(ID3D11DeviceContext* context, ID3D11Resource* resource, UINT subresource)
    {
        {
            std::lock_guard lock(BufferMutex);
            if (auto found = Buffers.find(resource); found != Buffers.end() && found->second.Mapped)
            {
                auto& contents = found->second;
                if (contents.Redirected)
                    std::memcpy(contents.Mapped, contents.Bytes.data(), contents.Bytes.size());
                else
                    std::memcpy(contents.Bytes.data(), contents.Mapped, contents.Bytes.size());
                contents.Mapped = nullptr;
                contents.Redirected = false;
                contents.Valid = true;
            }
        }
        Unmap(context, resource, subresource);
    }

    void STDMETHODCALLTYPE UpdateBuffer(ID3D11DeviceContext* context, ID3D11Resource* resource,
        UINT subresource, const D3D11_BOX* box, const void* data, UINT rowPitch, UINT depthPitch)
    {
        {
            std::lock_guard lock(BufferMutex);
            if (auto found = Buffers.find(resource); found != Buffers.end())
            {
                auto& bytes = found->second.Bytes;
                auto begin = box ? box->left : 0;
                auto end = box ? box->right : bytes.size();
                if (begin <= end && end <= bytes.size())
                {
                    std::memcpy(bytes.data() + begin, data, end - begin);
                    found->second.Valid |= begin == 0 && end == bytes.size();
                }
            }
        }
        UpdateSubresource(context, resource, subresource, box, data, rowPitch, depthPitch);
    }

    void CopyConstants(ID3D11Resource* destination, ID3D11Resource* source, UINT offset, const D3D11_BOX* box)
    {
        std::lock_guard lock(BufferMutex);
        auto target = Buffers.find(destination);
        if (target == Buffers.end())
            return;
        auto input = Buffers.find(source);
        if (input == Buffers.end())
        {
            ComPtr<ID3D11Buffer> buffer;
            if (FAILED(source->QueryInterface(IID_PPV_ARGS(&buffer))))
                return;
            D3D11_BUFFER_DESC description{};
            buffer->GetDesc(&description);
            Buffers[source].Bytes.resize(description.ByteWidth);
            target = Buffers.find(destination);
            input = Buffers.find(source);
        }
        auto begin = box ? box->left : 0;
        auto end = box ? box->right : input->second.Bytes.size();
        if (begin > end || end > input->second.Bytes.size() || offset + end - begin > target->second.Bytes.size() || !input->second.Valid)
        {
            target->second.Valid = false;
            return;
        }
        std::memcpy(target->second.Bytes.data() + offset, input->second.Bytes.data() + begin, end - begin);
        target->second.Valid |= offset == 0 && end - begin == target->second.Bytes.size();
    }

    void STDMETHODCALLTYPE CopyBuffer(ID3D11DeviceContext* context, ID3D11Resource* destination, ID3D11Resource* source)
    {
        CopyConstants(destination, source, 0, nullptr);
        CopyResource(context, destination, source);
    }

    void STDMETHODCALLTYPE CopyBufferRegion(ID3D11DeviceContext* context, ID3D11Resource* destination, UINT subresource,
        UINT x, UINT y, UINT z, ID3D11Resource* source, UINT sourceSubresource, const D3D11_BOX* box)
    {
        CopyConstants(destination, source, x, box);
        CopySubresourceRegion(context, destination, subresource, x, y, z, source, sourceSubresource, box);
    }

    using ReflectFunction = HRESULT(WINAPI*)(LPCVOID, SIZE_T, REFIID, void**);
    ReflectFunction Reflect{};
    HRESULT (STDMETHODCALLTYPE* CreateVertexShader)(ID3D11Device*, const void*, SIZE_T, ID3D11ClassLinkage*, ID3D11VertexShader**){};
    HRESULT (STDMETHODCALLTYPE* CreateDomainShader)(ID3D11Device*, const void*, SIZE_T, ID3D11ClassLinkage*, ID3D11DomainShader**){};
    HRESULT (STDMETHODCALLTYPE* CreatePixelShader)(ID3D11Device*, const void*, SIZE_T, ID3D11ClassLinkage*, ID3D11PixelShader**){};

    ComPtr<ID3D11ShaderReflection> Reflection(const void* code, SIZE_T length)
    {
        ComPtr<ID3D11ShaderReflection> result;
        if (Reflect)
            Reflect(code, length, __uuidof(ID3D11ShaderReflection), reinterpret_cast<void**>(result.GetAddressOf()));
        return result;
    }

    PreviousConstants PreviousLayout(const void* code, SIZE_T length)
    {
        PreviousConstants previous;
        auto reflection = Reflection(code, length);
        D3D11_SHADER_INPUT_BIND_DESC binding{};
        if (reflection && SUCCEEDED(reflection->GetResourceBindingDescByName("TemporalPrevious", &binding)))
        {
            auto buffer = reflection->GetConstantBufferByName("TemporalPrevious");
            D3D11_SHADER_BUFFER_DESC description{};
            if (SUCCEEDED(buffer->GetDesc(&description)))
            {
                previous.Slot = binding.BindPoint;
                previous.Size = description.Size;
                for (UINT i = 0; i < description.Variables; ++i)
                {
                D3D11_SHADER_VARIABLE_DESC field{};
                if (FAILED(buffer->GetVariableByIndex(i)->GetDesc(&field)) || !(field.uFlags & D3D_SVF_USED))
                    continue;
                UINT sourceBuffer{}, offset{};
                if (sscanf_s(field.Name, "Temporal_b%u_o%u_", &sourceBuffer, &offset) == 2)
                    previous.Fields.push_back({ sourceBuffer, offset, field.StartOffset, field.Size });
                }
                D3D11_SHADER_DESC shader{};
                reflection->GetDesc(&shader);
                for (UINT i = 0; i < shader.BoundResources; ++i)
                {
                D3D11_SHADER_INPUT_BIND_DESC resource{};
                reflection->GetResourceBindingDesc(i, &resource);
                UINT sourceSlot{};
                if (sscanf_s(resource.Name, "TemporalResource_t%u_", &sourceSlot) == 1)
                    previous.Resources.emplace_back(sourceSlot, resource.BindPoint);
                }
            }
        }
        return previous;
    }

    HRESULT STDMETHODCALLTYPE NewVertexShader(ID3D11Device* device, const void* code, SIZE_T length,
        ID3D11ClassLinkage* linkage, ID3D11VertexShader** output)
    {
        auto result = CreateVertexShader(device, code, length, linkage, output);
        if (SUCCEEDED(result) && output && *output)
        {
            auto previous = PreviousLayout(code, length);
            std::lock_guard lock(ShaderMutex);
            previous.Generation = ++ShaderGeneration;
            if (!previous.Fields.empty())
            {
                if (!ShadersReady11.exchange(true))
                    Log("DX11 motion shader detected, previous constants: %u bytes, slot %u", previous.Size, previous.Slot);
                VertexConstants[*output] = std::move(previous);
            }
            else
                VertexConstants.erase(*output);
        }
        return result;
    }

    HRESULT STDMETHODCALLTYPE NewDomainShader(ID3D11Device* device, const void* code, SIZE_T length,
        ID3D11ClassLinkage* linkage, ID3D11DomainShader** output)
    {
        auto result = CreateDomainShader(device, code, length, linkage, output);
        if (SUCCEEDED(result) && output && *output)
        {
            auto previous = PreviousLayout(code, length);
            std::lock_guard lock(ShaderMutex);
            previous.Generation = ++ShaderGeneration;
            if (!previous.Fields.empty())
            {
                if (!ShadersReady11.exchange(true))
                    Log("DX11 motion shader detected, previous constants: %u bytes, slot %u", previous.Size, previous.Slot);
                DomainConstants[*output] = std::move(previous);
            }
            else
                DomainConstants.erase(*output);
        }
        return result;
    }

    HRESULT STDMETHODCALLTYPE NewPixelShader(ID3D11Device* device, const void* code, SIZE_T length,
        ID3D11ClassLinkage* linkage, ID3D11PixelShader** output)
    {
        auto result = CreatePixelShader(device, code, length, linkage, output);
        if (SUCCEEDED(result) && output && *output)
        {
            auto reflection = Reflection(code, length);
            D3D11_SHADER_INPUT_BIND_DESC binding{};
            std::lock_guard lock(ShaderMutex);
            if (reflection && SUCCEEDED(reflection->GetResourceBindingDescByName("TemporalPixel", &binding)))
                PixelConstants[*output] = binding.BindPoint;
            else
                PixelConstants.erase(*output);
        }
        return result;
    }

    std::map<void*, SafetyHookInline> MethodHooks;

    template<typename T, typename U>
    void HookMethod(void** table, size_t index, T& original, U replacement)
    {
        auto [entry, added] = MethodHooks.try_emplace(table[index]);
        if (added)
            entry->second = safetyhook::create_inline(table[index], reinterpret_cast<void*>(replacement));
        original = entry->second.template original<T>();
    }

    using DrawKey = std::array<uint64_t, 8>;

    struct ResourceHistory11
    {
        ComPtr<ID3D11Resource> Previous;
        ComPtr<ID3D11Resource> Current;
        ComPtr<ID3D11ShaderResourceView> PreviousView;
        ComPtr<ID3D11ShaderResourceView> CurrentView;
        ID3D11Resource* Source{};
    };

    struct DrawHistory11
    {
        std::vector<uint8_t> Previous;
        std::vector<uint8_t> Current;
        std::vector<ResourceHistory11> Resources;
        uint64_t LastFrame{};
        bool Valid{};
        bool CurrentValid{};
    };

    std::map<DrawKey, DrawHistory11> Draws11;
    std::map<uint64_t, ComPtr<ID3D11Buffer>> ConstantUploads;
    ComPtr<ID3D11Buffer> ZeroConstants;

    int __cdecl BeginScene()
    {
        Collecting = true;
        auto reset = ResetVersion.load();
        if (reset != AppliedReset)
        {
            Draws11.clear();
            AppliedReset = reset;
        }
        std::erase_if(Draws11, [](const auto& item) { return item.second.LastFrame + 1 < Frame; });
        if (Frame <= 2 || Frame % 120 == 0)
            Log("Deferred frame %llu, tracked DX11 draws %zu", Frame, Draws11.size());
        return 0;
    }

    int __cdecl EndScene()
    {
#ifdef _DEBUG
        if (Frame % 120 == 0 && !Draws11.empty())
            Log("DX11 history: %zu draws, %zu valid, %zu entity draws", Draws11.size(),
                std::ranges::count_if(Draws11, [](const auto& draw) { return draw.second.Valid; }),
                std::ranges::count_if(Draws11, [](const auto& draw) { return draw.first[0] != 0; }));
#endif
        Collecting = false;
        Entities.clear();
        return 0;
    }

    SafetyHookInline ScenePhase;

    void __fastcall QueueScene(void* phase, void*)
    {
        if (!Enabled || reinterpret_cast<int*>(phase)[630] == -1)
            return ScenePhase.unsafe_thiscall<void>(phase);
        auto previous = BuildingScene;
        BuildingScene = true;
        ScenePhase.unsafe_thiscall<void>(phase);
        BuildingScene = previous;
    }

    ComPtr<ID3D11Buffer> Upload(ID3D11DeviceContext* context, std::span<const uint8_t> bytes, uint32_t stage = 0)
    {
        auto size = static_cast<UINT>((bytes.size() + 15) & ~15);
        auto& buffer = ConstantUploads[(static_cast<uint64_t>(stage) << 32) | size];
        if (!buffer)
        {
            ComPtr<ID3D11Device> device;
            context->GetDevice(&device);
            D3D11_BUFFER_DESC description{};
            description.ByteWidth = size;
            description.Usage = D3D11_USAGE_DYNAMIC;
            description.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
            description.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
            // The original methods: these uploads need no tracked copy
            if (FAILED(CreateBuffer(device.Get(), &description, nullptr, &buffer)))
                return {};
        }
        D3D11_MAPPED_SUBRESOURCE mapped{};
        if (FAILED(Map(context, buffer.Get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped)))
            return {};
        std::memcpy(mapped.pData, bytes.data(), bytes.size());
        Unmap(context, buffer.Get(), 0);
        return buffer;
    }

    bool CopyVertexResource(ID3D11Device* device, ID3D11Resource* source, ID3D11Resource** output)
    {
        D3D11_RESOURCE_DIMENSION dimension{};
        source->GetType(&dimension);
        if (dimension == D3D11_RESOURCE_DIMENSION_BUFFER)
        {
            D3D11_BUFFER_DESC description{};
            static_cast<ID3D11Buffer*>(source)->GetDesc(&description);
            description.Usage = D3D11_USAGE_DEFAULT;
            description.CPUAccessFlags = 0;
            description.BindFlags = D3D11_BIND_SHADER_RESOURCE;
            ComPtr<ID3D11Buffer> buffer;
            if (FAILED(device->CreateBuffer(&description, nullptr, &buffer)))
                return false;
            *output = buffer.Detach();
            return true;
        }
        if (dimension == D3D11_RESOURCE_DIMENSION_TEXTURE2D)
        {
            D3D11_TEXTURE2D_DESC description{};
            static_cast<ID3D11Texture2D*>(source)->GetDesc(&description);
            description.Usage = D3D11_USAGE_DEFAULT;
            description.CPUAccessFlags = 0;
            description.BindFlags = D3D11_BIND_SHADER_RESOURCE;
            description.MiscFlags &= D3D11_RESOURCE_MISC_TEXTURECUBE;
            ComPtr<ID3D11Texture2D> texture;
            if (FAILED(device->CreateTexture2D(&description, nullptr, &texture)))
                return false;
            *output = texture.Detach();
            return true;
        }
        return false;
    }

    bool NeedsResourceHistory(ID3D11Resource* resource)
    {
        D3D11_RESOURCE_DIMENSION dimension{};
        resource->GetType(&dimension);
        if (dimension == D3D11_RESOURCE_DIMENSION_BUFFER)
            return true;
        if (dimension == D3D11_RESOURCE_DIMENSION_TEXTURE2D)
        {
            D3D11_TEXTURE2D_DESC description{};
            static_cast<ID3D11Texture2D*>(resource)->GetDesc(&description);
            return description.CPUAccessFlags != 0 || (description.BindFlags & (D3D11_BIND_UNORDERED_ACCESS | D3D11_BIND_RENDER_TARGET));
        }
        return false;
    }

    bool SameLayout(ID3D11Resource* copy, ID3D11Resource* source)
    {
        D3D11_RESOURCE_DIMENSION a{}, b{};
        copy->GetType(&a);
        source->GetType(&b);
        if (a != b)
            return false;
        if (a == D3D11_RESOURCE_DIMENSION_BUFFER)
        {
            D3D11_BUFFER_DESC x{}, y{};
            static_cast<ID3D11Buffer*>(copy)->GetDesc(&x);
            static_cast<ID3D11Buffer*>(source)->GetDesc(&y);
            return x.ByteWidth == y.ByteWidth && x.StructureByteStride == y.StructureByteStride &&
                (x.MiscFlags & ~D3D11_RESOURCE_MISC_TEXTURECUBE) == (y.MiscFlags & ~D3D11_RESOURCE_MISC_TEXTURECUBE);
        }
        D3D11_TEXTURE2D_DESC x{}, y{};
        static_cast<ID3D11Texture2D*>(copy)->GetDesc(&x);
        static_cast<ID3D11Texture2D*>(source)->GetDesc(&y);
        return x.Width == y.Width && x.Height == y.Height && x.Format == y.Format && x.MipLevels == y.MipLevels && x.ArraySize == y.ArraySize;
    }

    struct SavedDraw11
    {
        uint32_t VertexSlot{}, PixelSlot{}, DomainSlot{};
        ComPtr<ID3D11Buffer> Vertex;
        ComPtr<ID3D11Buffer> Pixel;
        ComPtr<ID3D11Buffer> Domain;
        ComPtr<ID3D11BlendState> Blend;
        float BlendFactor[4]{};
        UINT SampleMask{};
        std::vector<std::pair<UINT, ComPtr<ID3D11ShaderResourceView>>> Resources;
        bool Active{};
        bool HasVertex{};
        bool HasDomain{};
        bool HasBlend{};
        std::vector<std::pair<UINT, ComPtr<ID3D11ShaderResourceView>>> DomainResources;

        void Restore(ID3D11DeviceContext* context)
        {
            if (!Active)
                return;
            if (HasBlend)
                context->OMSetBlendState(Blend.Get(), BlendFactor, SampleMask);
            if (HasVertex)
                context->VSSetConstantBuffers(VertexSlot, 1, Vertex.GetAddressOf());
            context->PSSetConstantBuffers(PixelSlot, 1, Pixel.GetAddressOf());
            if (HasDomain)
                context->DSSetConstantBuffers(DomainSlot, 1, Domain.GetAddressOf());
            for (auto& [slot, view] : DomainResources)
                context->DSSetShaderResources(slot, 1, view.GetAddressOf());
            for (auto& [slot, view] : Resources)
                context->VSSetShaderResources(slot, 1, view.GetAddressOf());
        }
    };

    // Whether the game's G-buffer is bound: motion and the previous constants only concern its draws
    bool GBufferBound{};
    void (STDMETHODCALLTYPE* SetTargets)(ID3D11DeviceContext*, UINT, ID3D11RenderTargetView* const*, ID3D11DepthStencilView*){};
    void (STDMETHODCALLTYPE* SetTargetsAndViews)(ID3D11DeviceContext*, UINT, ID3D11RenderTargetView* const*, ID3D11DepthStencilView*,
        UINT, UINT, ID3D11UnorderedAccessView* const*, const UINT*){};
    void (STDMETHODCALLTYPE* ClearState)(ID3D11DeviceContext*){};

    void TrackTargets(UINT count, ID3D11RenderTargetView* const* views)
    {
        GBufferBound = false;
        if (count <= 3 || !views || !views[3])
            return;
        ComPtr<ID3D11Resource> resource;
        views[3]->GetResource(&resource);
        GBufferBound = resource.Get() == NativeGBuffer();
    }

    void STDMETHODCALLTYPE SetRenderTargets(ID3D11DeviceContext* context, UINT count, ID3D11RenderTargetView* const* views, ID3D11DepthStencilView* depth)
    {
        TrackTargets(count, views);
        SetTargets(context, count, views, depth);
    }

    void STDMETHODCALLTYPE SetRenderTargetsAndViews(ID3D11DeviceContext* context, UINT count, ID3D11RenderTargetView* const* views,
        ID3D11DepthStencilView* depth, UINT first, UINT unordered, ID3D11UnorderedAccessView* const* access, const UINT* initial)
    {
        if (count != D3D11_KEEP_RENDER_TARGETS_AND_DEPTH_STENCIL)
            TrackTargets(count, views);
        SetTargetsAndViews(context, count, views, depth, first, unordered, access, initial);
    }

    void STDMETHODCALLTYPE ResetState(ID3D11DeviceContext* context)
    {
        GBufferBound = false;
        ClearState(context);
    }

    SavedDraw11 PrepareDraw11(ID3D11DeviceContext* context, UINT count, UINT start, UINT instances)
    {
        SavedDraw11 saved;
        if (!GBufferBound || ResolvedSceneFrame == Frame)
            return saved;
        if (!Enabled || !TargetReady)
        {
            ComPtr<ID3D11PixelShader> pixel;
            ComPtr<ID3D11VertexShader> vertex;
            ComPtr<ID3D11DomainShader> domain;
            context->PSGetShader(&pixel, nullptr, nullptr);
            context->VSGetShader(&vertex, nullptr, nullptr);
            context->DSGetShader(&domain, nullptr, nullptr);
            {
                std::lock_guard lock(ShaderMutex);
                auto ps = PixelConstants.find(pixel.Get());
                if (ps == PixelConstants.end())
                    return saved;
                saved.PixelSlot = ps->second;
                if (auto ds = DomainConstants.find(domain.Get()); ds != DomainConstants.end())
                {
                    saved.DomainSlot = ds->second.Slot;
                    saved.HasDomain = true;
                }
                if (auto vs = VertexConstants.find(vertex.Get()); vs != VertexConstants.end())
                {
                    saved.VertexSlot = vs->second.Slot;
                    saved.HasVertex = true;
                }
            }
            if (!ZeroConstants)
            {
                std::vector<uint8_t> zero(65536);
                D3D11_BUFFER_DESC description{};
                description.ByteWidth = static_cast<UINT>(zero.size());
                description.Usage = D3D11_USAGE_IMMUTABLE;
                description.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
                D3D11_SUBRESOURCE_DATA data{ zero.data(), 0, 0 };
                ComPtr<ID3D11Device> device;
                context->GetDevice(&device);
                device->CreateBuffer(&description, &data, &ZeroConstants);
            }
            if (!ZeroConstants)
                return saved;
            context->PSGetConstantBuffers(saved.PixelSlot, 1, &saved.Pixel);
            context->PSSetConstantBuffers(saved.PixelSlot, 1, ZeroConstants.GetAddressOf());
            if (saved.HasVertex)
            {
                context->VSGetConstantBuffers(saved.VertexSlot, 1, &saved.Vertex);
                context->VSSetConstantBuffers(saved.VertexSlot, 1, ZeroConstants.GetAddressOf());
            }
            if (saved.HasDomain)
            {
                context->DSGetConstantBuffers(saved.DomainSlot, 1, &saved.Domain);
                context->DSSetConstantBuffers(saved.DomainSlot, 1, ZeroConstants.GetAddressOf());
            }
            saved.Active = true;
            return saved;
        }
        {
            std::array<ComPtr<ID3D11RenderTargetView>, 4> targets;
            std::array<ID3D11RenderTargetView*, 5> raw{};
            ComPtr<ID3D11DepthStencilView> depth;
            context->OMGetRenderTargets(4, raw.data(), &depth);
            for (size_t i = 0; i < targets.size(); ++i)
                targets[i].Attach(raw[i]);
            if (!targets[3])
                return saved;
            ComPtr<ID3D11Resource> resource;
            targets[3]->GetResource(&resource);
            if (resource.Get() != NativeGBuffer())
                return saved;
            ComPtr<ID3D11Texture2D> texture;
            resource.As(&texture);
            D3D11_TEXTURE2D_DESC description{}, previous{};
            texture->GetDesc(&description);
            if (description.SampleDesc.Count != 1)
                return saved;
            if (MotionTexture11)
                MotionTexture11->GetDesc(&previous);
            if (!MotionTexture11 || previous.Width != description.Width || previous.Height != description.Height)
            {
                MotionTexture11.Reset();
                MotionTarget11.Reset();
                description.Format = DXGI_FORMAT_R16G16_FLOAT;
                description.Usage = D3D11_USAGE_DEFAULT;
                description.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
                description.CPUAccessFlags = description.MiscFlags = 0;
                ComPtr<ID3D11Device> device;
                context->GetDevice(&device);
                if (FAILED(device->CreateTexture2D(&description, nullptr, &MotionTexture11)) ||
                    FAILED(device->CreateRenderTargetView(MotionTexture11.Get(), nullptr, &MotionTarget11)))
                {
                    MotionTexture11.Reset();
                    return saved;
                }
                Log("Dedicated DX11 motion target: %ux%u", description.Width, description.Height);
            }
            if (MotionFrame11 != Frame)
            {
                const float invalid[]{ 2, 2, 0, 0 };
                context->ClearRenderTargetView(MotionTarget11.Get(), invalid);
                if (!Collecting)
                    BeginScene();
                if (SceneStarted)
                    SceneStarted();
                MotionFrame11 = Frame;
            }
            raw[4] = MotionTarget11.Get();
            context->OMSetRenderTargets(5, raw.data(), depth.Get());
        }
        ComPtr<ID3D11VertexShader> vertex;
        ComPtr<ID3D11DomainShader> domain;
        ComPtr<ID3D11PixelShader> pixel;
        context->VSGetShader(&vertex, nullptr, nullptr);
        context->DSGetShader(&domain, nullptr, nullptr);
        context->PSGetShader(&pixel, nullptr, nullptr);
        PreviousConstants metadata, domainMetadata;
        {
            std::lock_guard lock(ShaderMutex);
            auto vs = VertexConstants.find(vertex.Get());
            auto ps = PixelConstants.find(pixel.Get());
            if (vs == VertexConstants.end() || ps == PixelConstants.end())
                return saved;
            metadata = vs->second;
            if (auto ds = DomainConstants.find(domain.Get()); ds != DomainConstants.end())
            {
                domainMetadata = ds->second;
                saved.DomainSlot = domainMetadata.Slot;
                saved.HasDomain = true;
            }
            saved.VertexSlot = metadata.Slot;
            saved.PixelSlot = ps->second;
        }
        std::vector<uint8_t> constants;
        bool complete = true;
        uint64_t worldHash = 14695981039346656037ull;
        auto capture = [&](const PreviousConstants& layout, bool domainStage)
        {
            std::array<ComPtr<ID3D11Buffer>, 14> buffers;
            std::array<ID3D11Buffer*, 14> raw{};
            if (domainStage) context->DSGetConstantBuffers(0, static_cast<UINT>(raw.size()), raw.data());
            else context->VSGetConstantBuffers(0, static_cast<UINT>(raw.size()), raw.data());
            for (size_t i = 0; i < raw.size(); ++i)
                buffers[i].Attach(raw[i]);
            auto offset = constants.size();
            constants.resize(offset + layout.Size);
            {
                std::lock_guard lock(BufferMutex);
                for (const auto& field : layout.Fields)
                {
                    if (!buffers[field.Buffer])
                        continue;
                    auto found = Buffers.find(buffers[field.Buffer].Get());
                    if (found == Buffers.end() || !found->second.Valid)
                    {
                        complete = false;
                        break;
                    }
                    if (field.Source < found->second.Bytes.size())
                        std::memcpy(constants.data() + offset + field.Destination, found->second.Bytes.data() + field.Source,
                            std::min<size_t>(field.Size, found->second.Bytes.size() - field.Source));
                }
                if (!domainStage && Entities.empty())
                {
                    auto found = Buffers.find(buffers[0].Get());
                    if (found != Buffers.end() && found->second.Bytes.size() >= 64)
                        for (size_t i = 0; i < 64; ++i)
                            worldHash = (worldHash ^ found->second.Bytes[i]) * 1099511628211ull;
                }
            }
        };
        capture(metadata, false);
        if (saved.HasDomain)
            capture(domainMetadata, true);
        ComPtr<ID3D11Buffer> vertices, indices;
        UINT stride{}, offset{};
        context->IAGetVertexBuffers(0, 1, &vertices, &stride, &offset);
        context->IAGetIndexBuffer(&indices, nullptr, nullptr);
        auto entity = Entities.empty() ? nullptr : Entities.back();
        DrawKey key{ reinterpret_cast<uintptr_t>(entity), entity ? 0 : reinterpret_cast<uintptr_t>(vertices.Get()),
            reinterpret_cast<uintptr_t>(indices.Get()), (metadata.Generation << 32) ^ domainMetadata.Generation,
            count, indices ? start : 0, instances, entity ? 0 : worldHash };
        auto& history = Draws11[key];
        bool first = history.LastFrame != Frame;
        if (first)
        {
            history.Valid = complete && history.CurrentValid && history.LastFrame + 1 == Frame && history.Current.size() == constants.size();
            history.Previous.swap(history.Current);
            history.Current = constants;
            history.CurrentValid = complete;
            history.LastFrame = Frame;
            history.Resources.resize(metadata.Resources.size() + domainMetadata.Resources.size());
        }
        ComPtr<ID3D11Device> device;
        context->GetDevice(&device);
        for (size_t i = 0; i < history.Resources.size(); ++i)
        {
            bool domainStage = i >= metadata.Resources.size();
            auto [sourceSlot, destinationSlot] = domainStage ? domainMetadata.Resources[i - metadata.Resources.size()] : metadata.Resources[i];
            ComPtr<ID3D11ShaderResourceView> source, previous;
            if (domainStage) context->DSGetShaderResources(sourceSlot, 1, &source);
            else context->VSGetShaderResources(sourceSlot, 1, &source);
            if (source)
            {
                ComPtr<ID3D11Resource> resource;
                source->GetResource(&resource);
                auto& record = history.Resources[i];
                if (NeedsResourceHistory(resource.Get()))
                {
                    bool changed = record.Source != resource.Get();
                    if (changed && record.Current && SameLayout(record.Current.Get(), resource.Get()))
                        record.Source = resource.Get();
                    else if (changed)
                    {
                        record = {};
                        record.Source = resource.Get();
                        D3D11_SHADER_RESOURCE_VIEW_DESC description{};
                        source->GetDesc(&description);
                        if (!CopyVertexResource(device.Get(), resource.Get(), &record.Current) ||
                            !CopyVertexResource(device.Get(), resource.Get(), &record.Previous) ||
                            FAILED(device->CreateShaderResourceView(record.Current.Get(), &description, &record.CurrentView)) ||
                            FAILED(device->CreateShaderResourceView(record.Previous.Get(), &description, &record.PreviousView)))
                            record = {};
                        history.Valid = false;
                    }
                    if ((first || changed) && record.Current)
                    {
                        std::swap(record.Current, record.Previous);
                        std::swap(record.CurrentView, record.PreviousView);
                        context->CopyResource(record.Current.Get(), resource.Get());
                    }
                    previous = record.PreviousView;
                    history.Valid &= previous != nullptr;
                }
                else
                    previous = source;
            }
            ComPtr<ID3D11ShaderResourceView> original;
            if (domainStage)
            {
                context->DSGetShaderResources(destinationSlot, 1, &original);
                saved.DomainResources.emplace_back(destinationSlot, original);
                context->DSSetShaderResources(destinationSlot, 1, previous.GetAddressOf());
            }
            else
            {
                context->VSGetShaderResources(destinationSlot, 1, &original);
                saved.Resources.emplace_back(destinationSlot, original);
                context->VSSetShaderResources(destinationSlot, 1, previous.GetAddressOf());
            }
        }
        auto& previous = history.Valid ? history.Previous : constants;
        *reinterpret_cast<float*>(previous.data()) = history.Valid ? 1.0f : 0.0f;
        auto upload = Upload(context, std::span(previous).first(metadata.Size));
        ComPtr<ID3D11Buffer> domainUpload;
        if (saved.HasDomain)
        {
            *reinterpret_cast<float*>(previous.data() + metadata.Size) = history.Valid ? 1.0f : 0.0f;
            domainUpload = Upload(context, std::span(previous).subspan(metadata.Size), 1);
        }
        auto parameters = Upload(context, std::span(reinterpret_cast<const uint8_t*>(PixelParameters), sizeof(PixelParameters)), 2);
        if (!upload || !parameters || (saved.HasDomain && !domainUpload))
        {
            for (auto& [slot, view] : saved.Resources)
                context->VSSetShaderResources(slot, 1, view.GetAddressOf());
            for (auto& [slot, view] : saved.DomainResources)
                context->DSSetShaderResources(slot, 1, view.GetAddressOf());
            return {};
        }
        if (saved.HasDomain)
        {
            context->DSGetConstantBuffers(saved.DomainSlot, 1, &saved.Domain);
            context->DSSetConstantBuffers(saved.DomainSlot, 1, domainUpload.GetAddressOf());
        }
        context->VSGetConstantBuffers(saved.VertexSlot, 1, &saved.Vertex);
        context->PSGetConstantBuffers(saved.PixelSlot, 1, &saved.Pixel);
        context->VSSetConstantBuffers(saved.VertexSlot, 1, upload.GetAddressOf());
        context->PSSetConstantBuffers(saved.PixelSlot, 1, parameters.GetAddressOf());
        context->OMGetBlendState(&saved.Blend, saved.BlendFactor, &saved.SampleMask);
        auto& blend = MotionBlends11[saved.Blend.Get()];
        if (!blend.Motion)
        {
            blend.Original = saved.Blend;
            D3D11_BLEND_DESC description{};
            if (saved.Blend)
                saved.Blend->GetDesc(&description);
            else
                description.RenderTarget[0] = { FALSE, D3D11_BLEND_ONE, D3D11_BLEND_ZERO, D3D11_BLEND_OP_ADD,
                    D3D11_BLEND_ONE, D3D11_BLEND_ZERO, D3D11_BLEND_OP_ADD, D3D11_COLOR_WRITE_ENABLE_ALL };
            if (!description.IndependentBlendEnable)
                for (size_t i = 1; i < std::size(description.RenderTarget); ++i)
                    description.RenderTarget[i] = description.RenderTarget[0];
            description.IndependentBlendEnable = TRUE;
            description.RenderTarget[4] = { FALSE, D3D11_BLEND_ONE, D3D11_BLEND_ZERO, D3D11_BLEND_OP_ADD,
                D3D11_BLEND_ONE, D3D11_BLEND_ZERO, D3D11_BLEND_OP_ADD, D3D11_COLOR_WRITE_ENABLE_RED | D3D11_COLOR_WRITE_ENABLE_GREEN };
            device->CreateBlendState(&description, &blend.Motion);
        }
        if (blend.Motion)
        {
            context->OMSetBlendState(blend.Motion.Get(), saved.BlendFactor, saved.SampleMask);
            saved.HasBlend = true;
        }
        saved.Active = true;
        saved.HasVertex = true;
        return saved;
    }

    void (STDMETHODCALLTYPE* DrawIndexed)(ID3D11DeviceContext*, UINT, UINT, INT){};
    void (STDMETHODCALLTYPE* DrawIndexedInstanced)(ID3D11DeviceContext*, UINT, UINT, UINT, INT, UINT){};
    void (STDMETHODCALLTYPE* Draw)(ID3D11DeviceContext*, UINT, UINT){};
    void (STDMETHODCALLTYPE* DrawInstanced)(ID3D11DeviceContext*, UINT, UINT, UINT, UINT){};

    void STDMETHODCALLTYPE IndexedDraw(ID3D11DeviceContext* context, UINT count, UINT start, INT base)
    {
        auto saved = PrepareDraw11(context, count, start, 1);
        DrawIndexed(context, count, start, base);
        saved.Restore(context);
    }

    void STDMETHODCALLTYPE IndexedInstancedDraw(ID3D11DeviceContext* context, UINT count, UINT instances, UINT start, INT base, UINT first)
    {
        auto saved = PrepareDraw11(context, count, start, instances);
        DrawIndexedInstanced(context, count, instances, start, base, first);
        saved.Restore(context);
    }

    void STDMETHODCALLTYPE VertexDraw(ID3D11DeviceContext* context, UINT count, UINT start)
    {
        auto saved = PrepareDraw11(context, count, start, 1);
        Draw(context, count, start);
        saved.Restore(context);
    }

    void STDMETHODCALLTYPE InstancedDraw(ID3D11DeviceContext* context, UINT count, UINT instances, UINT start, UINT first)
    {
        auto saved = PrepareDraw11(context, count, start, instances);
        DrawInstanced(context, count, instances, start, first);
        saved.Restore(context);
    }

    void AttachDevice(ID3D11Device* device, ID3D11DeviceContext* context)
    {
        Log("DX11 device captured");
        auto table = *reinterpret_cast<void***>(device);
        if (table[12] != reinterpret_cast<void*>(&NewVertexShader))
        {
            HookMethod(table, 3, CreateBuffer, NewBuffer);
            HookMethod(table, 12, CreateVertexShader, NewVertexShader);
            HookMethod(table, 15, CreatePixelShader, NewPixelShader);
            HookMethod(table, 17, CreateDomainShader, NewDomainShader);
        }
        table = *reinterpret_cast<void***>(context);
        if (table[14] != reinterpret_cast<void*>(&MapBuffer))
        {
            HookMethod(table, 14, Map, MapBuffer);
            HookMethod(table, 15, Unmap, UnmapBuffer);
            HookMethod(table, 48, UpdateSubresource, UpdateBuffer);
            HookMethod(table, 46, CopySubresourceRegion, CopyBufferRegion);
            HookMethod(table, 47, CopyResource, CopyBuffer);
            HookMethod(table, 12, DrawIndexed, IndexedDraw);
            HookMethod(table, 13, Draw, VertexDraw);
            HookMethod(table, 20, DrawIndexedInstanced, IndexedInstancedDraw);
            HookMethod(table, 21, DrawInstanced, InstancedDraw);
            HookMethod(table, 33, SetTargets, SetRenderTargets);
            HookMethod(table, 34, SetTargetsAndViews, SetRenderTargetsAndViews);
            HookMethod(table, 110, ClearState, ResetState);
        }
    }

    SafetyHookInline DeviceCreation;

    HRESULT WINAPI CreateDevice(IDXGIAdapter* adapter, D3D_DRIVER_TYPE type, HMODULE software, UINT flags,
        const D3D_FEATURE_LEVEL* levels, UINT levelCount, UINT sdk, const DXGI_SWAP_CHAIN_DESC* description,
        IDXGISwapChain** swapChain, ID3D11Device** device, D3D_FEATURE_LEVEL* level, ID3D11DeviceContext** context)
    {
        auto modified = description ? *description : DXGI_SWAP_CHAIN_DESC{};
        const bool hdr = description && swapChain && HDR::Prepare(levels, levelCount, modified);
        auto result = DeviceCreation.stdcall<HRESULT>(adapter, type, software, flags, levels, levelCount, sdk,
            hdr ? &modified : description, swapChain, device, level, context);
        if (hdr && (FAILED(result) || !HDR::Attach(*swapChain)))
        {
            if (swapChain && *swapChain) { (*swapChain)->Release(); *swapChain = nullptr; }
            if (context && *context) { (*context)->Release(); *context = nullptr; }
            if (device && *device) { (*device)->Release(); *device = nullptr; }
            result = DeviceCreation.stdcall<HRESULT>(adapter, type, software, flags, levels, levelCount, sdk,
                description, swapChain, device, level, context);
        }
        if (SUCCEEDED(result) && device && *device && context && *context)
            AttachDevice(*device, *context);
        return result;
    }


}

export namespace TemporalMotion
{
    void SetResolveCallback(void (*callback)()) { ResolveScene = callback; }
    void SetSceneCallback(void (*callback)()) { SceneStarted = callback; }

    ID3D11Texture2D* AcquireSceneTexture11()
    {
        auto scene = NativeScene();
        if (scene) scene->AddRef();
        return scene;
    }
    void EndFrame()
    {
        EndScene();
        ++Frame;
    }

    void SetEnabled(bool enabled)
    {
        if (Enabled.exchange(enabled) != enabled)
            ++ResetVersion;
    }

    void Invalidate()
    {
        ++ResetVersion;
    }

    void OnLostDevice()
    {
        Invalidate();
        Draws11.clear();
        ConstantUploads.clear();
        ZeroConstants.Reset();
        MotionTarget11.Reset();
        MotionBlends11.clear();
        MotionTexture11.Reset();
        MotionFrame11 = 0;
    }

    bool IsReady()
    {
        TargetReady = NativeGBuffer() != nullptr;
        return TargetReady && ShadersReady11;
    }

    ID3D11Texture2D* AcquireTexture11()
    {
        if (!MotionTexture11 || MotionFrame11 != Frame)
            return nullptr;
        MotionTexture11->AddRef();
        return MotionTexture11.Get();
    }

    void SetPixelParameters(float inverseWidth, float inverseHeight, float jitterDeltaX, float jitterDeltaY)
    {
        PixelParameters[0] = inverseWidth;
        PixelParameters[1] = inverseHeight;
        PixelParameters[2] = jitterDeltaX;
        PixelParameters[3] = jitterDeltaY;
    }

    void Initialize()
    {
        Log("Initializing motion hooks");
        QueueCallbackData = reinterpret_cast<decltype(QueueCallbackData)>(hook::pattern("8B 4C 24 04 C6 40 03 00 89 48 10 8B 0A 89 48 14 C7 40 04 ? ? ? ? EB").get_first(-86));

        EntityDraw<0>::Hook = safetyhook::create_inline(hook::pattern("55 8B EC 83 E4 F0 81 EC 84 04 00 00 53 56 8B F1 8B 4E 30").get_first(), EntityDraw<0>::Draw);
        EntityDraw<1>::Hook = safetyhook::create_inline(hook::pattern("51 A1 ? ? ? ? 55 8B E9 64 8B 0D 2C 00 00 00 8B 0C 81 83 B9 7C 08 00").get_first(), EntityDraw<1>::Draw);
        EntityDraw<2>::Hook = safetyhook::create_inline(hook::pattern("83 EC 58 A1 ? ? ? ? 57 8B F9 F7 47 28 00 00 00 08").get_first(), EntityDraw<2>::Draw);
        EntityDraw<3>::Hook = safetyhook::create_inline(hook::pattern("51 56 8B F1 F7 86 F0 03 00 00 00 00 02 00").get_first(), EntityDraw<3>::Draw);
        ScenePhase = safetyhook::create_inline(hook::pattern("51 56 8B F1 83 BE D8 09 00 00 FF 0F 84 ? ? ? ? A1 ? ? ? ? 8B 0C").get_first(), QueueScene);

        auto target = hook::pattern("6A 03 68 ? ? ? ? FF D0 8D 4C 24 ? A3 ? ? ? ?").get_first<uint8_t>();
        GBufferTarget = *reinterpret_cast<void***>(target + 14);
        SceneTarget = *hook::get_pattern<void**>("80 3D ? ? ? ? 00 8B 35 ? ? ? ? 75 06 8B 35 ? ? ? ? A1", 17);

        auto compiler = LoadLibraryW(L"d3dcompiler_47.dll");
        if (compiler)
            Reflect = reinterpret_cast<ReflectFunction>(GetProcAddress(compiler, "D3DReflect"));
        auto d3d = LoadLibraryW(L"d3d11.dll");
        if (d3d && Reflect)
            DeviceCreation = safetyhook::create_inline(GetProcAddress(d3d, "D3D11CreateDeviceAndSwapChain"), CreateDevice);

        auto postfx = hook::pattern("68 ? ? ? ? E8 ? ? ? ? 83 C4 04 80 3D ? ? ? ? 00 74 0D 68 ? ? ? ? E8 ? ? ? ? 83 C4 04 68").get_first<uint8_t>(36);
        static auto RenderPostFX = *reinterpret_cast<void(__cdecl**)()>(postfx);
        static void(__cdecl* ResolveBeforePostFX)() = []()
        {
            if (ResolveScene && Enabled && MotionFrame11 == Frame && ResolvedSceneFrame != Frame && NativeScene())
            {
                ResolvedSceneFrame = Frame;
                ResolveScene();
            }
            RenderPostFX();
        };
        injector::WriteMemory(postfx, ResolveBeforePostFX, true);

    }
}
