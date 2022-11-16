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
local DEFAULT_EASE = "Linear";
local DEFAULT_DIRECTION = "InOut";

return function(source, time, easing, direction) 
	local sourceObservable = Blend.toPropertyObservable(source) or Rx.of(source);
	local easeingObservable = Blend.toPropertyObservable(easing) or Rx.of(easing);
	local directionObservable = Blend.toPropertyObservable(direction) or Rx.of(direction);

	local position = nil;
	local previousPosition = nil;
	local cachedValue = nil;
	
	return Observable.new(function(sub)
		local maid = Maid.new();
		local startTime = os.clock()
		
		-- easing properties
		local easingStyle = nil;
		maid:GiveTask(easeingObservable:Subscribe(function(easing)
			easingStyle = Enum.EasingStyle[easing or DEFAULT_EASE];
		end));
		
		local easingDirection = nil;
		maid:GiveTask(directionObservable:Subscribe(function(direction)
			easingDirection = Enum.EasingDirection[direction or DEFAULT_DIRECTION];
		end));
		
		-- animation
		local startAnimate, stopAnimate = StepUtils.bindToRenderStep(function()
			local elapsedTime = (os.clock() - startTime)
			local alpha = elapsedTime / time;
			local percentAlong = TweenService:GetValue(alpha, easingStyle, easingDirection);
			local posValue = previousPosition + percentAlong * (position - previousPosition);
			
			cachedValue = posValue;
			sub:Fire(SpringUtils.fromLinearIfNeeded(posValue));
			
			return alpha < 1;
		end);
		
		-- on position changed
		maid:GiveTask(stopAnimate);
		maid:GiveTask(sourceObservable:Subscribe(function(value)
			if (not cachedValue) then                
				cachedValue = SpringUtils.toLinearIfNeeded(value);
			end;
			
			startTime = os.clock()
			previousPosition = cachedValue;
			position = SpringUtils.toLinearIfNeeded(value);

			if (position and previousPosition) then                
				startAnimate();
			end;
		end));

		return maid;
	end);
end;
