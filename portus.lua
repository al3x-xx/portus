local ffi = require("ffi")
local memory = require("memory")
--local vitya = require("vector3d")

ffi.cdef([[
	typedef struct {
		float x, y, z;
	} vector3;

	typedef struct {
		struct {
			float red;
			float green;
			float blue;
			float alpha;
		};
		float size;
		float field_14;
		float life;
	} FxPrtMult_c;

	typedef struct {
		struct {
			char skip[0x14];
			int field_14;
		} *vtable;
	} FxPrim_c;

	typedef struct {
		char skip[0x78];
		FxPrim_c** PrimsList;
	} FxSystem_c;

	typedef struct {
		char skip[0x1C];
		FxSystem_c* prt_sand2;
	} Fx_c;
]]) -- gta_sa.idb discord.gg/X4H7ztF

main = function()
	local state = false

	sampRegisterChatCommand("portus", function()
		local res, x, y, z = getMarkPos()
		if not res or state or isCharInAnyCar(PLAYER_PED) then return end

		local pos, angle = getForwardPosAngle()
		createPortal(pos, angle)

		local timer = os.clock() + 5

		state = true

		lua_thread.create(function()
			while timer >= os.clock() and not isCharInAnyCar(PLAYER_PED) do
				if getDistanceBetweenCoords3d(pos.x, pos.y, pos.z, getCharCoordinates(PLAYER_PED)) <= 0.8 then
					--coord(x, y, z)
					createPortal(ffi.new("vector3", { x, y, z }), angle)
					setCharCoordinates(PLAYER_PED, x, y, z)
					break
				end
				wait(0)
			end
			state = false
		end)
	end)

	wait(-1)
end

getMarkPos = function()
	local res, x, y, z = getTargetBlipCoordinates()
	if not res then return false end
	ffi.cast("void(__cdecl*)(vector3*)", 0x40ED80)(ffi.new("vector3", { x, y, z }))
	return getTargetBlipCoordinates()
end

getForwardPosAngle = function()
	local x, y, z = getCharCoordinates(PLAYER_PED)
	local angle = -memory.getfloat(getCharPointer(PLAYER_PED) + 0x558)
	return ffi.new("vector3", { x + math.sin(angle) * 2.0, y + math.cos(angle) * 2.0, z - 1.0 }), angle
end

local addParticleWithoutRand = function(particle, position, velocity, particleData)
	ffi.cast("void(__thiscall*)(FxPrim_c*, vector3*, vector3*, float, FxPrtMult_c*, float, float, int)", particle.PrimsList[0].vtable.field_14)(particle.PrimsList[0], position, velocity, 1.0, particleData, 1.0, 1.0, 0)
end

createPortal = function(pos, angle)
	local fxC = ffi.cast("Fx_c*", 0xA9AE00)

	local sin_, cos_ = math.sin(angle + 1.57), math.cos(angle + 1.57)

	local velocity = ffi.new("vector3")
	local fxPrtFrame = ffi.new("FxPrtMult_c", { 0.0, 1.0, 1.0, 1.0, 0.03, 0.0, 1.5 })

	for i = 0.0, 3.1, 0.1 do
		addParticleWithoutRand(fxC.prt_sand2, ffi.new("vector3", { pos.x - sin_ * 1.0, pos.y - cos_ * 1.0, pos.z + i }), velocity, fxPrtFrame)
		addParticleWithoutRand(fxC.prt_sand2, ffi.new("vector3", { pos.x + sin_ * 1.0, pos.y + cos_ * 1.0, pos.z + i }), velocity, fxPrtFrame)
	end

	for i = 0.0, 1.1, 0.1 do
		addParticleWithoutRand(fxC.prt_sand2, ffi.new("vector3", { pos.x - sin_ * i, pos.y - cos_ * i, pos.z + 3.0 }), velocity, fxPrtFrame)
		addParticleWithoutRand(fxC.prt_sand2, ffi.new("vector3", { pos.x + sin_ * i, pos.y + cos_ * i, pos.z + 3.0 }), velocity, fxPrtFrame)
	end

	local fxPrtCenter = ffi.new("FxPrtMult_c", { 0.0, 0.9, 0.9, 0.8, 0.235, 0.0, 1.5 })

	pos.z = pos.z + 2.65
	addParticleWithoutRand(fxC.prt_sand2, pos, velocity, fxPrtCenter)

	pos.z = pos.z - 1.45
	addParticleWithoutRand(fxC.prt_sand2, pos, velocity, fxPrtCenter)
end
--[[
coord = function(x, y, z)
	local origPos, targetPos = vitya(getCharCoordinates(PLAYER_PED)), vitya(x, y, z)
	local origPos2 = origPos

	local data = allocateMemory(68)
	sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)

	local f = function(pos)
		setStructFloatElement(data, 6, pos.x)
		setStructFloatElement(data, 10, pos.y)
		setStructFloatElement(data, 14, pos.z)
		sampSendOnfootData(data)
	end

	while true do
		local between = targetPos - origPos
		if between:length() <= 25 then
			targetPos.z = targetPos.z + 1.0
			origPos2.z = targetPos.z
			f(targetPos) f(origPos2) f(origPos2)
			break
		else
			between:normalize()
			origPos = origPos + between * 25
			f(origPos)
		end
	end

	freeMemory(data)
end
--]]