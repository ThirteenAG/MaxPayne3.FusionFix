#include "../../source/TextureMipList.hpp"
#include <cassert>
#include <fstream>
#include <sstream>

int main(int argc, char** argv)
{
    using namespace TextureMips;
    NameList list;
    std::istringstream input("\xEF\xBB\xBF# UTF-8 BOM\r\n"
        "  Wall_D \t; comment\r\nwall_d\nFloor_D # comment\n\n; disabled\n");
    list.Read(input);
    assert(!list.Empty());
    assert(list.Contains("wall_d") && list.Contains("WALL_D"));
    assert(list.Contains("floor_d"));
    assert(!list.Contains("wall") && !list.Contains("wall_d_extra"));
    assert(list.Contains("wall_d.dds") && !list.Contains("disabled"));
    assert(list.Contains("pack:/WALL_D.dds"));
    assert(list.Contains("pack:/textures/WALL_D.DDS"));
    assert(list.Contains("textures\\wall_d.dds"));
    assert(!list.Contains("pack:/wall_d_extra.dds"));
    assert(!list.Contains("pack:/wall_d.dds.bak"));
    assert(CanSkip(2, 0, 0, 10, 1024, 512, 2048));
    assert(CanSkip(2, 0, 0, 2, 8, 8, 16));
    assert(!CanSkip(0, 0, 0, 10, 1024, 512, 2048));
    assert(!CanSkip(1, 0, 0, 10, 1024, 512, 2048));
    assert(!CanSkip(2, 1, 0, 10, 1024, 512, 2048));
    assert(!CanSkip(2, 0, 1, 10, 1024, 512, 2048));
    assert(!CanSkip(2, 0, 3, 10, 1024, 512, 2048));
    assert(!CanSkip(2, 0, 0, 1, 1024, 512, 2048));
    assert(!CanSkip(2, 0, 0, 2, 4, 8, 16));
    assert(!CanSkip(2, 0, 0, 2, 8, 4, 16));
    assert(!CanSkip(2, 0, 0, 2, 8, 8, 1));
    std::istringstream empty("# comments only\n\n");
    list.Read(empty);
    assert(list.Empty() && !list.Contains("wall_d"));
    if (argc > 1)
    {
        std::ifstream config(argv[1]);
        assert(config);
        list.Read(config);
        assert(list.Contains("brick_cinder_41b_dm"));
        assert(list.Contains("BRICK_CINDER_41B_DM"));
        assert(list.Contains("pack:/brick_cinder_41b_dm.dds"));
        assert(list.Contains("pack:/brick_cinder_41_nm.dds"));
        assert(!list.Contains("brick_cinder_41b_nm"));
        assert(!list.Contains("brick_cinder_41b_dm_extra"));
    }
}
