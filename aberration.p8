pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- variables --
gamestate="title"

function _init()
 gamestate="title"
 fill_starter_options()
--remove_abi(player_ab,1)
--print(#player_ab)
end

function _draw()
 cls()
 if gamestate=="title" then
  draw_title_screen()
 elseif gamestate=="upgrading" then
  draw_upgrade_screen()
 else
  draw_ab_list()
  draw_e_ab_list()
  draw_battlefield()
  render_sfx()
  draw_lives()
  if (gamestate=="playing") print_abi_tip()
  if gamestate=="victory" then
    c_print("you win", 84, 14)
    print("press ❎ to play again", 20, 96, 5)
   
  elseif gamestate=="defeat" then
    c_print("you lose", 84, 14)
    print("press ❎ to play again", 20, 96, 5)
   
  end
 end
end

function _update()
 if gamestate=="title" then
  update_title_screen()
 elseif gamestate=="playing" then
  update_battle()
 elseif gamestate=="upgrading" then
  update_upgrade_screen()
 elseif gamestate=="victory" then
  update_victory()
 elseif gamestate=="defeat" then
  update_defeat()
 end
end


-->8
-- gameplay --
player_hp = 5
enemy_hp = 5

function init_board()
 selector = 1
 e_select = 1
 selected = nil
 e_selected = nil
 nsel = selector
 player_ab={}
 enemy_ab={}
 player_hp = 5
 for ab in all(perm_player_ab) do
  add_ab(player_ab, copy_ab(ab))
 end
 enemy_hp = 5
 fill_enemy_roster()
 sfx_list = {}
end


function decide_match()
  if(enemy_hp<=0) return 1
  if(player_hp<=0) return -1
  all_e_ab_tired = true
  for e in all(enemy_ab) do
   if (e.sta>0 or e.disabled) all_e_ab_tired=false
  end
  all_ab_tired = true
  for e in all(player_ab) do
   if (e.sta>0 or e.disabled) all_ab_tired=false
  end
  if(all_e_ab_tired and all_ab_tired) return (player_hp > enemy_hp and 1 or -1)
  if(all_e_ab_tired) return 1
  if(all_ab_tired) return -1
  return 0
 end

function victory_con_check()
 if (enemy_hp <=0) return true
 
 
 if (all_ab_tired) return true
 return false
end

function defeat_con_check()
 if (player_hp <=0) return true
 all_ab_tired = true
 
 if (all_ab_tired) return true
 return false
end

function update_title_screen()
 if(btnp(❎)) then
  round_no=1
  gamestate="upgrading"
  --add_ab(perm_player_ab,create_ab(0,4,2,7,8,31))
  fill_starter_options()
  init_board()
  sfx(2)
 end
end

function update_upgrade_screen()
 if(btnp(⬆️)) then
  sfx(0) 
  upg_selector=(upg_selector-2)%3+1
 elseif(btnp(⬇️)) then
  sfx(0) 
  upg_selector=(upg_selector)%3+1
 end
 if(btnp(❎)) then
  add_ab(perm_player_ab, ab_options[upg_selector])
  if(#perm_player_ab<3) then
   if(ab_options[upg_selector].el==0) then
    add_ab(perm_player_ab,generate_starter_companion(1))
    add_ab(perm_player_ab,generate_starter_companion(2))
   elseif(ab_options[upg_selector].el==1) then
    add_ab(perm_player_ab,generate_starter_companion(0))
    add_ab(perm_player_ab,generate_starter_companion(2))
   else
    add_ab(perm_player_ab,generate_starter_companion(0))
    add_ab(perm_player_ab,generate_starter_companion(1))
   end
  end
  init_board()
  gamestate="playing"
  sfx(0)
 end
 if(btnp(🅾️) and #perm_player_ab>1) then
  init_board()
  gamestate="playing"
  sfx(0)
 end
end

function update_victory() 
 if(btnp(❎)) then
  if (round_no%2==0 and #perm_player_ab<6) then
   fill_upgr_options()
   gamestate="upgrading"
  else
   gamestate="playing"
  end
  round_no = round_no+1
  init_board()
  sfx(0)
 end
end

function update_defeat()
 if(btnp(❎)) then
  perm_player_ab = {}
  gamestate="title"
  sfx(0)
 end
end


function update_battle()
    update_sfx()
    while(player_ab[nsel].sta<=0) do
     nsel=(nsel)%#player_ab+1
    end
    if(btnp(⬆️)) then 
     nsel=(selector-2)%#player_ab+1
     while(player_ab[nsel].sta<=0 or player_ab[nsel].disabled) do
       nsel=(nsel-2)%#player_ab+1
     end
    elseif(btnp(⬇️)) then
     nsel=(selector)%#player_ab+1
     while(player_ab[nsel].sta<=0 or player_ab[nsel].disabled) do
      nsel=(nsel)%#player_ab+1
     end
    end
    if(btnp(❎)) then
     --select the aberration
     selected=player_ab[selector]
     --CPU selects its aberration
     e_select=flr(rnd(#enemy_ab))+1
     while(enemy_ab[e_select].sta<=0 or enemy_ab[e_select].disabled) do
      e_select=(e_select-2)%#enemy_ab+1
     end
     e_selected=enemy_ab[e_select]
     --Resolve Combat!!
     --if(selected.abi==3) return 99
     r=resolve_combat(selected, e_selected)
     if (r==-1) then
      create_txt_p("-"..dmg_dealt, 10+6*player_hp, 115, 0, -0.5, 8, 1, 16)
      sfx_dmg()
     elseif (r==1) then 
      create_txt_p("-"..dmg_dealt, 108-6*enemy_hp, 115, 0, -0.5, 8, 1, 16)
      sfx_dmg()
     elseif (r==0) then 
      create_txt_p("-0", 60, 60, 0, -0.5, 6, 5, 16) 
      sfx(6)
     end
     --Resolve post-combat abilities
     -- Stun --
     -- reenable past disabled aberrations
     for ab in all(player_ab) do
      ab.disabled = nil
     end
     for ab in all(enemy_ab) do
      ab.disabled = nil
     end
     -- stun the current ones
     if (selected.abi==4) then
      e_selected.disabled = 1
      create_txt_p("DISABLED", 70, 62, 0, -0.5, 5, 1, 16)
     end
     if (e_selected.abi==4) then
      selected.disabled = 1
      create_txt_p("DISABLED", 30, 62, 0, -0.5, 5, 1, 16)
     end
     -- Mimic --
     if (selected.abi==8 and e_selected.abi>0) then 
      selected.abi=e_selected.abi
      create_txt_p("COPIED", 34, 66, 0, -0.5, 7, 5, 16)
     end
     if (e_selected.abi==8 and selected.abi>0) then
      e_selected.abi=selected.abi
      create_txt_p("COPIED", 74, 66, 0, -0.5, 7, 5, 16)
     end
     -- Cromatic --
     for i, ab in pairs(player_ab) do
      if(ab.abi == 6) then ab.el = e_selected.el
      create_txt_p(el_caps_names[ab.el], 22, 16*i-1, 0, -0.5, el_colors[ab.el], 1, 16) 
      end
     end
     for i, ab in pairs(enemy_ab) do
      if(ab.abi == 6) then ab.el = selected.el
      create_txt_p(el_caps_names[ab.el], 110, 16*i-1, 0, -0.5, el_colors[ab.el], 1, 16) 
      end
     end
     -- Bulk-Up --
     for i,ab in pairs(player_ab) do
      if(ab.abi == 1 and ab != selected) then
        if(rnd(2)>1) then
         ab.atk = ab.atk+1
         create_txt_p("+1", 22, 16*i+6, 0, -0.5, 15, 5, 16)
        end
      end
     end
     for i, ab in pairs(enemy_ab) do
      if(ab.abi == 1) then
        if(rnd(2)>1 and ab!= e_selected) then
         ab.atk = ab.atk+1
         create_txt_p("+1", 110, 16*i+6, 0, -0.5, 15, 5, 16)
        end
      end
     end
    end
    v = decide_match()
    if (v==1) then
     gamestate="victory"
     sfx(1) 
    end
    if (v==-1) then
     gamestate="defeat"
     sfx(2) 
    end
    if(nsel!=selector) sfx(0) 
    selector=nsel

    --if victory_con_check() then
    -- gamestate="victory"
    --elseif defeat_con_check() then
    -- gamestate="defeat"
    --end
   end

-->8
-- ui --
el_caps_names = {
  [0]="BONE",
  [1]="MEAT",
  [2]="NERVE",
  [3]="IRON",
  [4]="PLANT",
  [5]="GHOST",
  [6]="CURSE",
  [7]="ANGEL"
}
el_names = {
  [0]="bone",
  [1]="meat",
  [2]="nerve",
  [3]="iron",
  [4]="plant",
  [5]="ghost",
  [6]="curse",
  [7]="angel"
}
el_colors = {
  [0]=9,
  [1]=14,
  [2]=12,
  [3]=6,
  [4]=4,
  [5]=13,
  [6]=2,
  [7]=15
}
text_c = {[0]=0, [1]=1, [2]=7, [3]=2, [4]=15, [5]=1, [6]=5, [7]=6, [8]=2, [9]=4, [10]=9, [11]=3, [12]=1, [13]=6, [14]=8, [15]=5}
abi_g = {[0]="",[1]="⧗",[2]="☉",[3]="◆",[4]="★",[5]="✽",[6]="●",[7]="♥",[8]="웃",[9]="⌂",[10]="🐱",[11]="ˇ",[12]="♪",[13]="😐"}
abi_tip = {
 [0]={"",""},
 [1]={"growing","50% chance damage increases for every turn not played"}, -- DONE
 [2]={"vicious","on win deals damage to opponent aberration's stamina"}, -- DONE
 [3]={"impervious","halves damage dealt by the opponent's aberration"}, -- DONE
 [4]={"stunning","opponent's aberration gets disabled for a turn"}, -- DONE
 [5]={"draining","removes opponent's aberration ability"},
 [6]={"chromatic","after every turn, changes to the element played by the oponent"}, -- DONE
 [7]={"vampiric","on win restores one heart if it damages the opponent"}, -- DONE
 [8]={"mimic","copies the ability of the opponent's aberration, if any"}, -- DONE
 [9]={"",""},
 [10]={"",""},
 [11]={"",""},
 [12]={"crying","on win gives one stamina to a random aberration you own"}, -- DONE
 [13]={"robot",""}}

ab_name = {
  [30]="mimic",
  [31]="khroma",
  [45]="cipactly",
  [46]="exourus",
  [47]="manaray",
  [64]="skelly",
  [65]="calcius",
  [66]="spikor",
  [80]="trangler",
  [81]="tarcle",
  [82]="harms",
  [96]="seeyu",
  [97]="brian",
  [98]="xyodis",
  [112]="poker",
  [113]="anglo",
  [114]="zukrit",
  [128]="danceria",
  [129]="thorny",
  [130]="fauner",
  [144]="spook",
  [145]="rition",
  [146]="ternalis",
  [160]="darpup",
  [161]="sightful",
  [162]="jawler",
  [176]="naynos",
  [177]="mariel",
  [178]="kew"
}

round_no=1
upg_selector=1
selector = 1
e_select = 1
selected = nil
e_selected = nil
nsel = selector

function c_print(text, y, c)
  y = y or 60
  if c==nil then
    print(text, 64-#tostr(text)*2-1, y)
  else
    print(text, 64-#tostr(text)*2-1, y, c)
  end
end

function cx_print(text, x, y, c)
  x = x or 64
  y = y or 60
  if c==nil then
    print(text, x-#tostr(text)*2-1, y)
  else
    print(text, x-#tostr(text)*2-1, y, c)
  end
end

function c_multi_print(text, y, lim, c)
 y = y or 60
 lim = lim or 128
 t = split(text," ")
 val = ""
 l = 0
 for s in all(t) do
  ss = tostr(s)
  if #val*4+#ss*4>lim then
   c_print(val, y+l, c)
   val = ""
   l = l+6
  end
  val=val.." "..ss
 end
 c_print(val, y+l, c)
end

function print_abi_tip()
 print(abi_g[player_ab[selector].abi], 61, 77, 7)
 c_multi_print(abi_tip[player_ab[selector].abi][1], 85, 96)
 c_multi_print(abi_tip[player_ab[selector].abi][2], 93, 96)
end

function draw_lives()
 for i=1,player_hp do
  print("♥", 12+6*i, 120, 8)
 end
 for i=1,enemy_hp do
  print("♥", 109-6*i, 120, 8)
 end
end

function draw_ui_ab(i, ab, s)
  c = (ab.sta>0 and not ab.disabled and el_colors[ab.el] or 5)
  d = text_c[c]
  rectfill(0, 16*i-s, 31+s, 16*i+10-s, c)
  spr_outln(ab.sp,1+s,16*i+1-s)
  pal(6,d)
  spr(6,11+s,16*i+1-s)
  spr(8,19+s,16*i+1-s)
  spr(7,11+s,16*i+6-s)
  spr(8,19+s,16*i+6-s)
  snum_print(ab.sta,22+s,16*i+1-s)
  snum_print(ab.atk,22+s,16*i+6-s)
  pal(6,6)
  print(abi_g[ab.abi],29+s,16*i+10-s,1)
  print(abi_g[ab.abi],28+s,16*i+9-s,7)
 end

function draw_ui_e_ab(i, ab, s)
 c = (ab.sta>0 and not ab.disabled and el_colors[ab.el] or 5)
 d = text_c[c]
 rectfill(128, 16*i-s, 96-s, 16*i+10-s, c)
 spr_outln(ab.sp,118-s,16*i+1-s,true)
 if(is_strong(player_ab[selector].el, ab.el)) spr(9, 90-s, 16*i+1-s)
 if(is_strong(ab.el, player_ab[selector].el)) spr(10, 90-s, 16*i+1-s)
 pal(6,d)
 spr(6,98-s,16*i+1-s)
 spr(8,107-s,16*i+1-s)
 spr(7,98-s,16*i+6-s)
 spr(8,107-s,16*i+6-s)
 snum_print(ab.sta,110-s,16*i+1-s)
 snum_print(ab.atk,110-s,16*i+6-s)
 pal(6,6)
 print(abi_g[ab.abi],92+s,16*i+10-s,2)
 print(abi_g[ab.abi],91+s,16*i+9-s,7)
end


function draw_selected_ab(i, ab)
 draw_ui_ab(i, ab, 1)
end

function draw_unselected_ab(i, ab)
 draw_ui_ab(i, ab, 0)
end

function draw_e_selected_ab(i, ab)
 draw_ui_e_ab(i, ab, 1)
end

function draw_e_unselected_ab(i, ab)
 draw_ui_e_ab(i, ab, 0)
end

function draw_ab_list()
 for i=1,6 do
  rectfill(0, 16*i, 9, 16*i+10, 1)
 end
 for i, ab in pairs( player_ab ) do
  if selector==i then
  draw_selected_ab(i, ab)
  else
  draw_unselected_ab(i, ab)
  end
 end
end

function draw_e_ab_list()
 for i=1,6 do
  rectfill(128, 16*i, 118, 16*i+10, 2)
 end
 for i, ab in pairs( enemy_ab ) do
  if e_select==i then
  draw_e_selected_ab(i, ab)
  else
  draw_e_unselected_ab(i, ab)
  end
 end
end


function snum_print(val, x, y, c)
 sp=0
 if val>=10 then
 	a=flr(val/10)
 	sspr(8+a*4,0,3,4,x,y)
 	sp=sp+4
 end
 b=val%10
 sspr(8+b*4,0,3,4,x+sp,y)
end

function spr_outln(sp, x, y, flip)
 pal({[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0})
 spr(sp,x+1,y+1,1.0,1.0,flip)
 pal()
 spr(sp,x,y,1.0,1.0,flip)
end


function draw_battlefield()
 if(selected!=nil and e_selected!=nil) then
 spr(selected.sp, 40, 64)
 spr(e_selected.sp, 80, 64,1.0,1.0,true)
 end
 print("round", 55, 116, 2)
 print("round", 54, 115, 12)
 print(round_no, 63, 122, 2)
 print(round_no, 62, 121, 12)
end

function draw_title_screen()
 c_print("aberrations", 60, 14)
 --print(#ab_options, 5, 5)
 print("press ❎ to play", 33, 72, 5)
 print("game by GnOGR", 72, 116)
 print("for the acerola jam 0 - 2024", 12, 122)
end

function draw_option(i)
  s = i==upg_selector and 1 or 0
  bc = el_colors[ab_options[i].el]
  tc = text_c[bc]
  rectfill(38,2+42*(i-1), 126, 41+42*(i-1), 1)
  rectfill(38+s,2+42*(i-1)-s, 126+s, 41+42*(i-1)-s, bc)
  cx_print(ab_name[ab_options[i].sp], 88+s, 4+42*(i-1)-s, tc)
  --cx_print(icon, 42, 22+42*(i-1), 10)
  spr_outln(ab_options[i].sp, 45+s,  20+42*(i-1)-s)
  print("element:", 62+s, 14+42*(i-1)-s)
  print(el_names[ab_options[i].el], 94+s, 14+42*(i-1)-s)
  print("stamina:"..ab_options[i].sta, 62+s, 21+42*(i-1)-s)
  print("atk points:"..ab_options[i].atk, 62+s, 28+42*(i-1)-s)
  print(abi_g[ab_options[i].abi], 116+s, 5+42*(i-1)-s,1)
  print(abi_g[ab_options[i].abi], 115+s, 4+42*(i-1)-s,7)
  --cx_print(title, 82, 2+42*(i-1), 10)
  --cx_print(title, 82, 2+42*(i-1), 10)

end

function draw_ab_upg_list()
  for i=1,6 do
   rectfill(0, 16*i, 9, 16*i+10, 1)
  end
  for i, ab in pairs( perm_player_ab ) do
   draw_unselected_ab(i, ab)
  end
 end

function draw_upgrade_screen()
  --rectfill(2, 16, 41, 108, 13)
  --rectfill(44, 16, 83, 108, 13)
  --rectfill(86, 16, 125, 108, 13)
 draw_ab_upg_list()
 draw_option(1)
 draw_option(2)
 draw_option(3)
 print("❎: pick",0,114)
 if(#perm_player_ab>1)print("🅾️: skip",0,121)
end
  
-->8
-- aberrations --

--base = {["hp"]=5,["sta"]=3,["atk"]=1,["el"]=0,["abi"]=0,["sp"]=0}
--rock = {["hp"]=5,["sta"]=5,["atk"]=1,["el"]=4,["abi"]=0,["sp"]=16}
--paper = {["hp"]=5,["sta"]=5,["atk"]=1,["el"]=15,["abi"]=0,["sp"]=17}
--scissors = {["hp"]=5,["sta"]=5,["atk"]=1,["el"]=13,["abi"]=0,["sp"]=18}
win_matrix = {[0]={2,5,7},[2]={1,4},[1]={0,3,4},[3]={2,5,6},[4]={0,3,6},[5]={1,4,6},[6]={0, 1, 2},[7]={6}}

ab_options = {}
perm_player_ab={}
player_ab = {}
enemy_ab = {}


function is_strong(el1, el2)
 strong = false
 for e in all(win_matrix[el1]) do
  if (e == el2) strong = true
 end
 return strong
end

function add_ab(l, ab)
 add(l, ab)
end

function remove_abi(l,i)
 del(l, l[i])
end

function create_ab(hp, sta, atk, el, abi, sp, plr)
  plr = plr or 0
  ab = {["hp"]=hp,["sta"]=sta,["atk"]=atk,["el"]=el,["abi"]=abi,["sp"]=sp, ["plr"]=0}
	return ab
end

function copy_ab(ab)
  return create_ab(ab.hp, ab.sta, ab.atk, ab.el, ab.abi, ab.sp, ab.plr)
end

function fill_enemy_roster()
 enemy_ab = {}
 if(round_no<5) then
  for i=1,3 do
   add_ab(enemy_ab, generate_random_ab(flr(rnd(3))))
   enemy_ab[i].abi=0
  end
 else
  for i=1,3 do
   add_ab(enemy_ab, generate_random_ab())
  end
 end
 n = flr((rnd(2)+round_no)/2)
 for i=1,min(n,3) do
  add_ab(enemy_ab, generate_random_ab())
 end
 a = flr((rnd(4)+round_no-2)/3)
 for i=1,a do
  ab = rnd(enemy_ab)
  abi = rnd({1,2,3,4,7,12})
  ab.abi = abi
 end
end

function fill_upgr_options()
  ab_options = {}
  add_ab(ab_options, generate_random_ab())
  add_ab(ab_options, generate_random_ab())
  add_ab(ab_options, generate_random_ab())
end

function fill_starter_options()
  ab_options = {}
  add_ab(ab_options, generate_starter_ab(0))
  add_ab(ab_options, generate_starter_ab(1))
  add_ab(ab_options, generate_starter_ab(2))
end

function generate_rare_ab()
 c = flr(rnd(3))
 if (c==0) then return create_ab(0,4,2,7,6,31) -- Chromatic orb
 elseif (c==1) then return create_ab(0,4,2,7,8,30) -- Mimic
 elseif (c==2) then return create_ab(0,1,6,1,2,45)-- Cipactly
 elseif (c==3) then return create_ab(0,5,2,1,3,46) -- Exobull
 elseif (c==3) then return create_ab(0,7,1,1,4,47) -- Neuray
 end
end

function generate_random_ab(element)
  generate_rares = true
  if(element!=nil) generate_rares = false
  if(generate_rares and rnd(20)>19) return generate_rare_ab()
  element = element or flr(rnd(8))
  gtype = flr(rnd(3))
  sta = 0
  atk = 0
  if gtype==0 then
    sta=3
    atk=2
  elseif gtype==1 then
    sta=5
    atk=1
  else
    sta=2
    atk=3
  end
  if(element==6) sta=sta-1
  if(element==7) then
   sta=sta+2
   atk=atk-1
  end
  ability = rnd(6)>5 and rnd({1,2,3,4,7,12}) or 0
  return create_ab(0,sta,atk,element,ability,64+gtype+16*element)
end

function generate_starter_companion(element)
 return create_ab(0,5,1,element,0,65+16*element)
end

function generate_starter_ab(element)
 ability = rnd({1,2,3,4,7,12})
 return create_ab(0,3,2,element,ability,64+16*element)
end

dmg_dealt = 0
function move(x, y, side)
 win = false
 for val in all(win_matrix[x.el]) do
  if (y.el == val) win=true
 end
 if win then
  -- Reduce player health taking impervious into account
  dmg = x.atk

  if(y.abi==3) dmg = flr(dmg/2)

  if(side==0)  enemy_hp = enemy_hp - dmg
  if(side==1)  player_hp = player_hp - dmg

  dmg_dealt = dmg
  -- Check for ability effects
  if(x.abi==2) then
   y.sta = max(0, y.sta-dmg)
   create_txt_p("-"..dmg, 110-88*side, 16*(selector+side*(e_select-selector))+3, 0, -0.5, 9, 1, 16)
  end
  if(x.abi==7) then
   if(side==0) player_hp=min(5,player_hp+1)
   if(side==1) enemy_hp=min(5,enemy_hp+1)
   create_txt_p("+1", 10+6*player_hp+side*(98-6*enemy_hp-6*player_hp), 115, 0, -0.5, 15, 5, 16)
  end
  if(x.abi==12) then
   if(side==0) then
    i = flr(rnd(#player_ab))+1
    if(i==selector) i=(i-2)%#player_ab+1
    if(i!=selector) then player_ab[i].sta=player_ab[i].sta+1
    create_txt_p("+1", 22, 16*i+3, 0, -0.5, 15, 5, 16) end
   else
    i = flr(rnd(#enemy_ab))+1
    if(i==e_select) i=(i-2)%#enemy_ab+1
    if(i!=e_select) then enemy_ab[i].sta=enemy_ab[i].sta+1
    create_txt_p("+1", 110, 16*i+3, 0, -0.5, 15, 5, 16) end
   end
  end
  return true -- did win
 end
 return false -- did not win
end

function resolve_combat(a, b)
 
 a.sta = a.sta-1
 b.sta = b.sta-1
 -- Check if player won the exchange (0) --
 if move(a, b, 0) then
  --create_txt_p("A WINS B", 50, 20, 0, -0.5, 9, 1, 16)
  return 1
 end
 -- Check if oponent won the exchange (1) --
 if move(b, a, 1) then
  --create_txt_p("B WINS A", 50, 20, 0, -0.5, 9, 1, 16)
  return -1
 end
 -- No win? then return zero --
 return 0
end
-->8
-- controls --

-->8
-- sfx --

sfx_list = {}

function render_txt_p(a)
 print(a.val, a.x+1, a.y+1, a.c2)
 print(a.val, a.x, a.y, a.c1)
end

function render_sfx()
 for e in all(sfx_list) do
  render_txt_p(e)
 end
end

function update_sfx()
 for e in all(sfx_list) do
  update_txt_p(e)
 end
end

function update_txt_p(a)
 a.t = a.t+1
 if a.t>=a.lfsp then
  del(sfx_list, a)
  return
 end
 a.x = a.x+a.dx
 a.y = a.y+a.dy
end

function sfx_dmg()
 if(dmg_dealt==0) then sfx(6)
 elseif(dmg_dealt==1) then sfx(3)
 elseif(dmg_dealt==2) then sfx(4)
 else sfx(5)
 end
end

function create_txt_p(val, x, y, dx, dy, c1, c2, lfsp)
 add(sfx_list, {["val"]=val,["x"]=x,["y"]=y,["dx"]=dx,["dy"]=dy,["c1"]=c1,["c2"]=c2,["t"]=0,["lfsp"]=lfsp})
end
__gfx__
00000000066006000660666060606660066066600660666006606660060006600000000000000bb300099098000e600000000000000000000000000000000000
0000000060606600606006606060600060000060066066606600060060606060600000000000bbb3000099800ee6e66000000000000000000000000000000000
007007006060060006000060666006606660006060600060006006006660666000000000000bbb30000999980e66ee6000000000000000000000000000000000
000770006600666066606600006066606660006066606660660006006060600060000000b0bbb300009998980e66ee6000000000000000000000000000000000
000770000000000000000000000000000000000000000000000000000000000000000000bbbb3000099980000e66ee6000000000000000000000000000000000
0070070000000000000000000000000000000000000000000000000000000000000000000bb30000999800000e66ee6000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000b3bb00009980000000e6e60000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000003003000088000000000e600000000000000000000000000000000000
0000660007777700660000760000000000000000000000000000ffff0000f0f0f0070700a0000000000015000005550000000000000000000500555000000000
0005670007ddd7700660077000000000000000000000000000f5f8f800000f0f0f05770790000555001155500055990000000000000000000050585000888000
0055660007777770006667000000000000000000000000000f05ffff0050008f50fff0f080000959001195500555555000000000000000000050555008877700
0156567007dddd7000066000000000000000000000000000f05f00ff000f00ff0f5f5f008005155001115555851555d8000000000000000001555000087777c0
1565667007777770007767000000000000000000000000000f05000005f505005f00ffff555151050115559598d55d88000000000000000010555550087777c0
1566666507dddd708880088800000000000000000000000005f0ff002f000f50050f0f8f500150050159a555a9d51d9a00000000000000001015500500777cc0
111666550777777080800808000000000000000000000000505f0f0055f5f5f0055f0fff1005000501115a5500551500000000000000000000100500000ccc00
0115551000777770088008800000000000000000000000005f05ff00252525005000000f10050015111111150011110000000000000000000100050000000000
000000000000000000006700000001ee0000000000000000000088ee008888000087870000000300000700000b3bb3b00000000000002220007800780001dd00
0000000000000000000067000000022e00000000000000000028887802888280028888800bb0b2b0006a7b00033b3b3b000000002802888000f077f0001ddcd0
000000000000000000018810000012220000000000000000028828880282008008888880030b28230007bb803328382000000000282e800007ffff770ddddddd
0000000000000000011111100000222000000000000000002888220000280080888282880000b2b0001832000322b2b00000000022676880f7f8ff870d1d1d1d
00000000000000001116117000012e000000000000000000288282e0000820008e828088000333300003b8b003bb2b30000000002e787688f75fff700d0d0d0d
000000000000000001101100001222ee0000000000000000288280800008800088e2008800b300b001b8b300003202b00000000002676288f575fff00c0d0d0c
000000000000000001001100012222200000000000000000288220200028280082800028033b0bb001232bb80302003000000000008e8028f5f50407060c0c06
0000000000000000000011001111112e00000000000000002002000002e888808820008803033000001111300000000000000000022888004545040400060600
000000000000000000000000000000000000000000000000000000000000dff00000d66002002200000eee002002200000000000000000000000000000000000
000000000000000000000000000000000000000000000000000d1670000d1fdf0d00c6c000022ee000e0e0002200202200000000000000000000000000000000
000000000000000000000000000000000000000000000000101162c70001dddd0d00d660002e00e000eeee000e00e0e000000000000000000000000000000000
000000000000000000000000000000000000000000000000111d6c1700d1111000d00d06020e002000eee00020eeeee000000000000000000000000000000000
00000000000000000000000000000000000000000000000001112c1c00d00000010dd66d02e0ee0000e0e00002e0e00000000000000000000000000000000000
000000000000000000000000000000000000000000000000001dd2c6010d000001d00606000e2000000e00002eeeee0200000000000000000000000000000000
00000000000000000000000000000000000000000000000000011dd0010d00000000d60020200002002020000e0200e000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000010d0000000006000000ee200000200002202202200000000000000000000000000000000
0000ffff0000f0f0f007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f5f8f800000f0f0f05770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f05ffff0050008f50fff0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f05f00ff000f00ff0f5f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f05000005f505005f00ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05f0ff002f000f50050f0f8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505f0f0055f5f5f0055f0fff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5f05ff00252525005000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888008888000087870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0028887802888880028888e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02882888028600800888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28882200002800808882828800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2882e280000870008e82808800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
288280800008800088e2008e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28822020002878008280002800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2002000002e888808820008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000dff00000d66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d1670000d1fdf0d00c6c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101162c70001dddd0d00d66100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111d6c1700d1111000d00d0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01112c1c00d00000100dd66d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001dd2c6010d000001d0060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011dd0010d00000000d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000010d00000000d600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0000000000015000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000555001155500055990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80000959001195500555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8005155001115555851555d800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555151050115559598d55d8800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500150050159a555a9d51d9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1005000501115a550055150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10050015111111150011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000300000700000b3bb3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb0b2b0006a7b00033b3b3b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030b28230007bb803328382000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b2b0001832000322b2b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000333300003b8b003bb2b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b300b001b8b300003202b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
033b0bb001232bb80302003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03033000001111300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02002200000eee002002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022ee000e0e0002200202200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002e00e000eeee000e00e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020e002000eee00020eeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02e0ee0000e0e00002e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e2000000e00002eeeee0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20200002002020000e0200e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee200000200002202202200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000550000015500010755000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55005550155557500100555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55005755575751000505575500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555051155001505171700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555550505557501555110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555150505751550555110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55115050101515751505717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50105050001101151501155500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa00000007000007aa70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a77777a000aa7000700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000007700a7a770007aa70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a07770770aaa77770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0078707700aaaaa00077778700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077077a000aaa000770777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a777a00000a0000707000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000070000700007002b75030750307503370033700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000a0000375503a5503c5503a5503c5503e5503f5503f5503f5500050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
100a00003755035550345503355031550315503270031700325503255032700327002970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000236511e1511b151191511615114151111510f151000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
00010000316512e65129151271512415122151201511e1511c1511915117151000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
0101000031657316572f6572d6572a257292572615723157211571e1571c157085570555703557035570355703557035570000700007000070000700007000070000700007000070000700007000070000700007
00020000091500a3500b3500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
