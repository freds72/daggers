-- lightweight version of the game engine
-- return shortest angle to target
function shortest_angle(target_angle,angle)
	local dtheta=target_angle-angle
	if dtheta>0.5 then
		angle+=1
	elseif dtheta<-0.5 then
		angle-=1
	end
	return angle
end


function make_player()
    local pos,angle,angular={4,4,1},0,0
    local vel,acc=0,0    
    -- find player pos
    for idx,id in pairs(_sprite_grid) do
        if id==20 then
            pos={(idx&0x0.00ff)<<16,(idx&0x0.ff)<<8,idx\1}
            -- remove starting point
            -- _sprite_grid[idx]=nil
            break
        end
    end
    return {
        orient=function()
            return pos,angle
        end,
        control=function()
            local dx,dy=0,0
            if(btn(0)) dx=1
            if(btn(1)) dx=-1
            if(btn(2)) dy=-1
            if(btn(3)) dy=1
            acc+=dy/64
            angular+=dx/128
        end,
        update=function()            
            vel+=acc
            vel*=0.85
            acc*=0.7
            angle+=angular
            angular*=0.5
            local c,s=cos(angle),-sin(angle)
            pos=v_add(pos,{-s,c,0},vel)
        end
    }
end

function game_state()
    local u,d=_update,_draw
    local plyr=make_player()
    local cam=make_cam(64,70,64,0.125)
    local angle=0

    _update=function()
        plyr:control()
        plyr:update()
        
        local p,a=plyr:orient()
        angle=lerp(shortest_angle(a,angle),a,0.2)   
        cam:control(p,-0.180,angle,7)
    end
    _draw=function()        
        _draw=function()
            -- cls(12)
            map(0,0,0,0,16,16)
            draw_grid(cam)
            local p,a=plyr:orient()
            draw_sprite(cam,v_add(p,{-0.5,-0.5,0}),19,true)
        end
    end
end