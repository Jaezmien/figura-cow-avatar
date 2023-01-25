-- GNanim.lua
-- By: GNamimates
local a={remote_view=true}local b={}local c={}local d=require("libs.TimerAPI")if not d then print("Missing Dependency: TimerAPI")end;local e=getmetatable;do local f=0;for g,h in pairs(animations)do for i,j in pairs(h)do f=f+1;local k=e(j)k.id=f end end end;function b.getAnimID(l)return e(l).id end;local m={}m.__index=m;function m:addAnimations(...)for n,i in pairs{...}do table.insert(self.animations,i)end;return self end;function m:play()local i=self.animations;if#i>0 then if self.type=="RANDOM"then self.currentPlaying=math.random(1,#i)end;if self.type=="ROUND_ROBBIN"then self.currentPlaying=self.currentPlaying%#i+1 end;local o=i[self.currentPlaying]if o then o:stop()end;if self.type~="ALL"then o:play()else for n,h in pairs(i)do h:play()end end end;return self end;function m:stop()local i=self.animations;if#i>0 then if self.type~="ALL"then i[self.currentPlaying]:stop()else for n,h in pairs(i)do h:stop()end end end end;function m:speed(p)local i=self.animations;if#i>0 then if self.type~="ALL"then i[self.currentPlaying]:speed(p)else for n,h in pairs(i)do h:speed(p)end end end end;function m:getLoop()local o=self.animations[self.currentPlaying]if o then o:getLoop()end end;function m:blend(q)local i=self.animations;if self.type~="ALL"then i[self.currentPlaying]:blend(q)else for n,h in pairs(i)do h:blend(q)end end;return self end;function m:getPlayState(q)local o=self.animations[self.currentPlaying]if o then o:getPlayState(q)end;return self end;function m:setGroupType(r)self.type=r;return self end;function b.newAnimationGroup()local s={animations={},type="ROUND_ROBBIN",currentPlaying=1}setmetatable(s,m)return s end;local t={}local u={}u.__index=u;function u:setState(v,w)if self.state~=v or w then if not self.timer.paused then if self.lastState then self.lastState:stop()end;if self.state then self.state:stop()end end;self.lastState=self.state;self.state=v;if self.onChange then self.onChange(self.state,self.lastState)end;if self.state and self.state.blendTime then self.timer.duration=self.state.blendTime else self.timer.duration=self.blendTime end;if self.blendTime~=0 and self.lastState~=self.state then if self.state then self.state:stop()self.state:play()end;self.timer:play()else if self.lastState then self.lastState:stop()end;if self.state then self.state:play()end end end end;function b.newStateMachine()local x={state=nil,lastState=nil,override=false,blendTime=0.1,overallOpacity=1}x.timer=d:new("RENDER",x.blendTime,false,false,function()if x.state then x.state:blend(1)end;if x.lastState then x.lastState:blend(0)x.lastState:stop()end end,function(y,z)if x.state then x.state:blend(y)end;if x.lastState then x.lastState:blend(1-y)end end)setmetatable(x,u)table.insert(t,x)return x end;return b