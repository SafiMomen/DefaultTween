-- DefaultTween
-- DarkModule
-- 11/13/2022

----- LOADED SERVICES -----
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");

 ----- PRIVATE VARIABLES -----
local require = require(script.Parent.loader).load(script)

----- PRIVATE FUNCTION -----
local Blend = require("Blend");
local Rx = require("Rx");
local Observable = require("Observable");
local StepUtils = require("StepUtils");
local SpringUtils = require("SpringUtils");
local Maid = require("Maid");

----- MAIN CLASS -----

return function(source, time, easing, direction) 
      local sourceObservable = Blend.toPropertyObservable(source) or Rx.of(source);

    local easingStyle = Enum.EasingStyle[easing];
    local easingDirection = Enum.EasingDirection[direction];

    local position = nil;
    local previousPosition = nil;

    --TODO: add time, easing, direction as observables.
    return Observable.new(function(sub)
        local maid = Maid.new();

        local startTime = os.clock()

        local startAnimate, stopAnimate = StepUtils.bindToRenderStep(function()
            local elapsedTime = (os.clock() - startTime)
            local alpha = elapsedTime / time;
            local percentAlong = TweenService:GetValue(alpha, easingStyle, easingDirection);
            local posValue = previousPosition + percentAlong * (position - previousPosition);
            sub:Fire(SpringUtils.fromLinearIfNeeded(posValue));

            return alpha < 1;
        end);

        maid:GiveTask(stopAnimate);
        maid:GiveTask(sourceObservable:Subscribe(function(value)
            stopAnimate();
                        
            if (position) then                
                startTime = os.clock()
                previousPosition = position;
            end;
            position = SpringUtils.toLinearIfNeeded(value);

            if (position and previousPosition) then                
                startAnimate();
            end;
        end));

        return maid;
    end);
end;
