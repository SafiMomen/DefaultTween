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

		local startAnimate, stopAnimate = StepUtils.bindToRenderStep(function(t)
			local a = (tick() - t) / time;
			local p = TweenService:GetValue(a, easingStyle, easingDirection);
			local posValue = previousPosition + p * (position - previousPosition);
			sub:Fire(SpringUtils.fromLinearIfNeeded(posValue));

			return a < 1;
		end);

		maid:GiveTask(stopAnimate);
		maid:GiveTask(sourceObservable:Subscribe(function(value)
			if (position) then				
				previousPosition = position;
			end;
			position = SpringUtils.toLinearIfNeeded(value);

			if (position and previousPosition) then				
				startAnimate(tick());
			end;
		end));

		return maid;
	end);
end;
