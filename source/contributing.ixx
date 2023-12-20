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
            Player playa = Natives::GET_PLAYER_PED(0);
            int32_t health = Natives::GET_PED_HEALTH(playa);
            std::cout << health << std::endl;
        };
    }
} Contributing;