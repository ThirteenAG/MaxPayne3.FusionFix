module;

#include <common.hxx>
#include <iostream>

export module contributing;

import common;
import natives;

class Contributing
{
public:
    Contributing()
    {
        FusionFix::onInitEvent() += []()
        {
            // Add your code here
        };


        FusionFix::onGameProcessEvent() += []() 
        {
            auto fps = Natives::GET_CURRENT_FPS();
            std::cout << fps << std::endl;
        };
    }
} Contributing;