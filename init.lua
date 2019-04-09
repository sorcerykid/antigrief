--------------------------------------------------------
-- Minetest :: Antigrief Mod (antigrief)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2016-2019, Leslie E. Krause
--
-- ./games/minetest_game/mods/antigrief/init.lua
--------------------------------------------------------

local old_register_node = minetest.register_node
local old_register_craftitem = minetest.register_craftitem
local old_override_item = minetest.override_item

function patch_craftitemdef( def, cur_def )
	if def.allow_place then
		def._on_place = def.on_place or cur_def.on_place or minetest.item_place
		def.on_place = function( itemstack, player, pointed_thing )
			local pos = pointed_thing.under
			local node = minetest.get_node( pos )

			-- allow on_rightclick callback of pointed_thing to intercept placement, otherwise
			-- placement is dependent on anti-grief rules of this item (if hook is defined)

			if minetest.registered_nodes[ node.name ].on_rightclick then
				minetest.registered_nodes[ node.name ].on_rightclick( pos, node, player, itemstack )
			elseif not def.allow_place or def.allow_place( pos, player ) then
				return def._on_place( itemstack, player, pointed_thing )
			end
			return itemstack
		end
	end

	return def
end

function patch_nodedef( def, cur_def )
	if def.allow_place then
		def._on_place = def.on_place or cur_def.on_place or minetest.item_place
		def.on_place = function( itemstack, player, pointed_thing )
			local pos = pointed_thing.under
			local node = minetest.get_node( pos )

			-- allow on_rightclick callback of pointed_thing to intercept placement, otherwise
			-- placement is dependent on anti-grief rules of this item (if hook is defined)

			if minetest.registered_nodes[ node.name ].on_rightclick then
				minetest.registered_nodes[ node.name ].on_rightclick( pos, node, player, itemstack )
			elseif not def.allow_place or def.allow_place( pos, player ) then
				return def._on_place( itemstack, player, pointed_thing )
			end
			return itemstack
		end
	end
	if def.allow_punch then
		def._on_punch = def.on_punch or cur_def.on_punch or minetest.node_punch
		def.on_punch = function( pos, node, player )
			-- punching is dependent on anti-grief rules of this item (currently only used by tnt)

			if not def.allow_punch or def.allow_punch( pos, player ) then
				def._on_punch( pos, node, player )
			end
		end
	end
	return def
end

minetest.register_node = function ( name, def )
	old_register_node( name, patch_nodedef( def ) ) 
end

minetest.register_craftitem = function ( name, def )
	old_register_craftitem( name, patch_craftitemdef( def ) ) 
end

minetest.override_item = function ( name, def )
	local cur_def = minetest.registered_items[ name ]
	if cur_def.type == "node" then
		old_override_item( name, patch_nodedef( def, cur_def ) )
	elseif cur_def.type == "craft" then
		old_override_item( name, patch_craftitemdef( def, cur_def ) )
	end
end
