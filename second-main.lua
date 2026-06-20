-- ══════════════════════════════════════════════════════════
--  Cookie Clicker + Card Shop  —  main.lua
-- ══════════════════════════════════════════════════════════

local window                     = {}
local cookie                     = {}
local cookie_shadow_opacity      = 0.8
local base_cookie_shadow_opacity = 0.8
local bg_image, red_bg_image, card_image
local points_font, small_font, tiny_font

-- ── Score / mult ──────────────────────────────────────────
local total_clicks               = 0
local mult                       = 1

-- ── Shop thresholds ───────────────────────────────────────
local shop_visit_count           = 0
local next_shop_threshold        = 100 -- first shop at 100, then +150, +200 …
local shop_displayed             = false
local can_click_card             = false
local shop_wait_timer            = 0
local card_mult_factor           = 1 -- grows each visit

-- ── UI boxes ──────────────────────────────────────────────
local top_ui_box                 = {}
local bottom_ui_box              = {}
local points_text                = {}
local mult_text                  = {}
local shop                       = {}

-- ── Text scale anim ───────────────────────────────────────
local ts                         = {
    x = 1,
    y = 1,
    base_x = 1,
    base_y = 1,
    big_x = 1.5,
    big_y = 1.5,
    pumped = false
}

-- ── Cards ─────────────────────────────────────────────────
local cards                      = {}
local card_rotation_timer        = 0
local CARD_DISPLAY_SCALE         = 0.4 -- cards shown at 0.4× in shop

-- ── Card animation state machine ──────────────────────────
-- States: "idle" → "to_center" → "flip_out" → "flip_in"
--       → "travel_to_mult" → "merge" → "done"
local sel                        = nil -- selected card table
local anim_state                 = "idle"
local anim_t                     = 0

-- Tunable durations (seconds)
local DUR_TO_CENTER              = 0.45
local DUR_FLIP_OUT               = 0.18
local DUR_FLIP_IN                = 0.18
local DUR_SHOW                   = 0.7
local DUR_TRAVEL                 = 0.55
local DUR_MERGE                  = 0.5
local DUR_DONE                   = 0.25

-- ── Particles ─────────────────────────────────────────────
local particles                  = {} -- floating click sparkles
local fireworks                  = {} -- milestone bursts
local floaters                   = {} -- floating "+N mult" text ribbons

-- ── Milestone tracking ────────────────────────────────────
local milestones                 = { 500, 1000, 2500, 5000, 10000 }
local next_milestone_idx         = 1

-- ── Cookie wobble ─────────────────────────────────────────
local cookie_wobble              = 0 -- extra rotation on click
local cookie_wobble_speed        = 0
local global_timer               = 0

-- ═══════════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════════
local function Lerp(a, b, t) return a + (b - a) * t end
local function EaseOut(t) return 1 - (1 - t) * (1 - t) end
local function EaseInOut(t)
    if t < 0.5 then return 2 * t * t else return -1 + (4 - 2 * t) * t end
end
local function Clamp01(t) return math.max(0, math.min(1, t)) end

local function RandRange(a, b) return a + math.random() * (b - a) end

-- ── New card ──────────────────────────────────────────────
local function NewCard()
    return {
        mult = math.random(-20, 20) * card_mult_factor,
        x = 0,
        y = 0,
        rotation = 0,
        rotation_offset = RandRange(-10, 10),
        scale_x = CARD_DISPLAY_SCALE,
        scale_y = CARD_DISPLAY_SCALE,
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
        visible = true,
        -- anim scratch
        ax = 0,
        ay = 0,
        asx = CARD_DISPLAY_SCALE,
        asy = CARD_DISPLAY_SCALE,
    }
end

local function InitCards()
    cards = {}
    for i = 1, 4 do cards[i] = NewCard() end
end

-- ═══════════════════════════════════════════════════════════
--  PARTICLE SYSTEMS
-- ═══════════════════════════════════════════════════════════
local function SpawnSparkle(x, y, count)
    for i = 1, (count or 8) do
        local angle = RandRange(0, math.pi * 2)
        local speed = RandRange(60, 180)
        particles[#particles + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - RandRange(20, 80),
            life = 1,
            max_life = 1,
            r = RandRange(0.9, 1),
            g = RandRange(0.7, 1),
            b = RandRange(0, 0.4),
            size = RandRange(3, 7),
        }
    end
end

local function SpawnFirework(x, y)
    local hue = math.random() -- random colour per burst
    local count = math.random(30, 50)
    for i = 1, count do
        local angle = RandRange(0, math.pi * 2)
        local speed = RandRange(80, 320)
        -- convert hue to RGB simply
        local r = math.abs(math.sin(hue * math.pi * 2))
        local g = math.abs(math.sin((hue + 0.333) * math.pi * 2))
        local b = math.abs(math.sin((hue + 0.667) * math.pi * 2))
        fireworks[#fireworks + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 1,
            max_life = RandRange(0.6, 1.2),
            r = r,
            g = g,
            b = b,
            size = RandRange(3, 9),
            trail = {},
        }
    end
    -- // SOUND EFFECT: play a firework explosion "boom + crackle" here
end

local function SpawnMilestoneFireworks()
    local w, h = window.width, window.height
    for i = 1, 5 do
        SpawnFirework(RandRange(w * 0.15, w * 0.85), RandRange(h * 0.05, h * 0.5))
    end
end

local function SpawnFloater(text, x, y, is_positive)
    floaters[#floaters + 1] = {
        text = text,
        x = x,
        y = y,
        vy = -55,
        life = 1,
        max_life = 1.4,
        r = is_positive and 0.2 or 1,
        g = is_positive and 1 or 0.2,
        b = 0.2,
        scale = 1.3,
    }
end

-- ═══════════════════════════════════════════════════════════
--  LOVE.LOAD
-- ═══════════════════════════════════════════════════════════
function love.load()
    window.width          = love.graphics.getWidth()
    window.height         = love.graphics.getHeight()

    -- cookie
    cookie.sprite         = love.graphics.newImage("images/cookie.png")
    cookie.x              = window.width / 2
    cookie.y              = window.height / 2
    cookie.base_y         = window.height / 2
    cookie.shadow_y       = window.height / 2 + 12
    cookie.rotation       = 0
    cookie.scale_x        = 0.5
    cookie.scale_y        = 0.5
    cookie.base_scale     = 0.5
    cookie.hover_scale    = 0.56
    cookie.spd            = 18
    cookie.pressed        = false
    cookie.hovered        = false
    cookie.cursor_default = love.mouse.getSystemCursor("arrow")
    cookie.cursor_pointer = love.mouse.getSystemCursor("hand")
    -- // SOUND EFFECT: preload ambient background music loop here

    -- images
    bg_image              = love.graphics.newImage("images/background.jpg")
    red_bg_image          = love.graphics.newImage("images/red-background.jpg")
    card_image            = love.graphics.newImage("images/card.png")

    -- fonts
    points_font           = love.graphics.newFont("fonts/mightysouly.ttf", 80)
    small_font            = love.graphics.newFont("fonts/mightysouly.ttf", 46)
    tiny_font             = love.graphics.newFont("fonts/mightysouly.ttf", 28)

    -- UI positions
    top_ui_box            = { x = 0, y = 30, width = window.width, height = 90 }
    bottom_ui_box         = { x = 0, y = window.height - 130, width = window.width, height = 130 }
    points_text           = { x = window.width / 2, y = top_ui_box.y + top_ui_box.height / 2 }
    mult_text             = { x = window.width / 2, y = bottom_ui_box.y + bottom_ui_box.height / 2 }

    -- shop (slides up from bottom, taller to avoid overlap)
    shop                  = {
        x = 0,
        y = window.height,
        width = window.width,
        height = window.height * 0.72, -- taller panel
    }

    InitCards()
    PositionCards()

    math.randomseed(os.time())
end

-- ═══════════════════════════════════════════════════════════
--  LOVE.UPDATE
-- ═══════════════════════════════════════════════════════════
function love.update(dt)
    global_timer = global_timer + dt

    -- ── cookie hover / scale ──────────────────────────────
    if not shop_displayed and anim_state == "idle" then
        CheckCookieHovered()
    else
        cookie.hovered = false
    end

    local target_scale = cookie.hovered and cookie.hover_scale or cookie.base_scale
    cookie.scale_x = Lerp(cookie.scale_x, target_scale, cookie.spd * dt)
    cookie.scale_y = Lerp(cookie.scale_y, target_scale, cookie.spd * dt)
    love.mouse.setCursor(cookie.hovered and cookie.cursor_pointer or cookie.cursor_default)

    -- wobble decay
    cookie_wobble_speed = cookie_wobble_speed * (1 - 12 * dt)
    cookie_wobble       = cookie_wobble + cookie_wobble_speed * dt
    cookie.rotation     = cookie_wobble

    -- shadow / press
    if cookie.pressed then
        cookie.y              = Lerp(cookie.y, cookie.shadow_y, 12 * dt)
        cookie_shadow_opacity = Lerp(cookie_shadow_opacity, 0, 12 * dt)
    else
        cookie.y              = Lerp(cookie.y, cookie.base_y, 12 * dt)
        cookie_shadow_opacity = Lerp(cookie_shadow_opacity, base_cookie_shadow_opacity, 12 * dt)
    end

    -- cookie collision box
    local sw      = cookie.sprite:getWidth() * cookie.scale_x
    local sh      = cookie.sprite:getHeight() * cookie.scale_y
    cookie.left   = cookie.x - sw / 2; cookie.right = cookie.x + sw / 2
    cookie.top    = cookie.y - sh / 2; cookie.bottom = cookie.y + sh / 2

    -- ── score / shop check ───────────────────────────────
    if not shop_displayed and anim_state == "idle" then
        CheckCurrentPoints()
    end

    -- ── milestone fireworks ───────────────────────────────
    local score = total_clicks * mult
    if next_milestone_idx <= #milestones and score >= milestones[next_milestone_idx] then
        SpawnMilestoneFireworks()
        SpawnMilestoneFireworks()
        next_milestone_idx = next_milestone_idx + 1
        -- // SOUND EFFECT: play a triumphant fanfare jingle for milestone here
    end

    -- ── text scale pulse ──────────────────────────────────
    local tx = ts.pumped and ts.big_x or ts.base_x
    local ty = ts.pumped and ts.big_y or ts.base_y
    ts.x = Lerp(ts.x, tx, 80 * dt)
    ts.y = Lerp(ts.y, ty, 80 * dt)

    -- ── shop slide ────────────────────────────────────────
    local shop_target = shop_displayed and (window.height - shop.height + 30) or window.height
    shop.y = Lerp(shop.y, shop_target, 12 * dt)

    -- ── card click delay ─────────────────────────────────
    if shop_displayed and not can_click_card then
        shop_wait_timer = shop_wait_timer + dt
        if shop_wait_timer >= 1.0 then
            can_click_card = true
            -- // SOUND EFFECT: play a soft "cards ready / shimmer" chime here
        end
    end

    -- ── card idle layout ─────────────────────────────────
    PositionCards()
    RotateCards(dt)
    CalculateCardCollisionBox()

    -- ── card animation state machine ─────────────────────
    UpdateCardAnim(dt)

    -- ── particles ────────────────────────────────────────
    UpdateParticles(dt)
    UpdateFireworks(dt)
    UpdateFloaters(dt)
end

-- ═══════════════════════════════════════════════════════════
--  CARD ANIMATION STATE MACHINE
-- ═══════════════════════════════════════════════════════════
function UpdateCardAnim(dt)
    if anim_state == "idle" then return end

    local card = sel
    local cx   = window.width / 2
    local cy   = window.height / 2

    anim_t     = anim_t + dt

    -- ── to_center: lerp card to screen centre ────────────
    if anim_state == "to_center" then
        local p  = Clamp01(anim_t / DUR_TO_CENTER)
        local e  = EaseOut(p)
        card.ax  = Lerp(card.ax, cx, e * 12 * dt + 0)   -- use lerp for smoothness
        card.ay  = Lerp(card.ay, cy, e * 12 * dt + 0)
        card.ax  = card.ax + (cx - card.ax) * (12 * dt)
        card.ay  = card.ay + (cy - card.ay) * (12 * dt)
        card.asx = Lerp(card.asx, CARD_DISPLAY_SCALE, 12 * dt)
        card.asy = Lerp(card.asy, CARD_DISPLAY_SCALE, 12 * dt)

        if math.abs(card.ax - cx) < 2 and math.abs(card.ay - cy) < 2 then
            card.ax, card.ay = cx, cy
            anim_state       = "flip_out"
            anim_t           = 0
            -- // SOUND EFFECT: play "card whoosh / swipe" here
        end

        -- ── flip_out: squish scale_x to 0 ────────────────────
    elseif anim_state == "flip_out" then
        local p  = Clamp01(anim_t / DUR_FLIP_OUT)
        card.asx = CARD_DISPLAY_SCALE * (1 - p)
        if anim_t >= DUR_FLIP_OUT then
            card.asx   = 0
            anim_state = "flip_in"
            anim_t     = 0
        end

        -- ── flip_in: grow scale_x back from 0 ────────────────
    elseif anim_state == "flip_in" then
        local p  = Clamp01(anim_t / DUR_FLIP_IN)
        card.asx = CARD_DISPLAY_SCALE * p
        if anim_t >= DUR_FLIP_IN then
            card.asx   = CARD_DISPLAY_SCALE
            anim_state = "show_result"
            anim_t     = 0
            -- apply mult change now (flip reveals value)
            mult       = mult + card.mult
            if mult < 1 then mult = 1 end
            local is_pos = card.mult >= 0
            local lbl    = (is_pos and "+" or "") .. tostring(card.mult) .. " MULT"
            SpawnFloater(lbl, cx, cy - 80, is_pos)
            if is_pos then
                SpawnSparkle(cx, cy, 20)
                -- // SOUND EFFECT: play a bright "ding / power-up" here
            else
                SpawnSparkle(cx, cy, 10)
                -- // SOUND EFFECT: play a dull "thud / negative buzz" here
            end
        end

        -- ── show_result: card stays at centre ────────────────
    elseif anim_state == "show_result" then
        if anim_t >= DUR_SHOW then
            anim_state         = "travel"
            anim_t             = 0
            -- save start position for travel lerp
            sel.travel_start_x = cx
            sel.travel_start_y = cy
            -- // SOUND EFFECT: play a "swoosh" travelling sound here
        end

        -- ── travel: card flies to mult text position ─────────
    elseif anim_state == "travel" then
        local p  = Clamp01(anim_t / DUR_TRAVEL)
        local e  = EaseInOut(p)
        card.ax  = Lerp(sel.travel_start_x, mult_text.x, e)
        card.ay  = Lerp(sel.travel_start_y, mult_text.y, e)
        -- shrink as it travels
        card.asx = Lerp(CARD_DISPLAY_SCALE, 0.08, e)
        card.asy = Lerp(CARD_DISPLAY_SCALE, 0.08, e)
        if anim_t >= DUR_TRAVEL then
            card.ax, card.ay = mult_text.x, mult_text.y
            anim_state       = "merge"
            anim_t           = 0
            -- burst at mult position
            SpawnSparkle(mult_text.x, mult_text.y, 25)
            ts.pumped = true
            -- // SOUND EFFECT: play a "merge boom / impact" sound here
        end

        -- ── merge: big text scale punch then relax ────────────
    elseif anim_state == "merge" then
        if anim_t >= DUR_MERGE then
            ts.pumped  = false
            anim_state = "done"
            anim_t     = 0
        end

        -- ── done: cleanup, reset ──────────────────────────────
    elseif anim_state == "done" then
        if anim_t >= DUR_DONE then
            sel            = nil
            anim_state     = "idle"
            anim_t         = 0
            shop_displayed = false
            InitCards()
            PositionCards()
            -- // SOUND EFFECT: play a quiet "ready" tick as game resumes
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  PARTICLE UPDATES
-- ═══════════════════════════════════════════════════════════
function UpdateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x     = p.x + p.vx * dt
        p.y     = p.y + p.vy * dt
        p.vy    = p.vy + 200 * dt -- gravity
        p.life  = p.life - dt / p.max_life
        if p.life <= 0 then table.remove(particles, i) end
    end
end

function UpdateFireworks(dt)
    for i = #fireworks, 1, -1 do
        local f = fireworks[i]
        -- store trail
        f.trail[#f.trail + 1] = { x = f.x, y = f.y, life = f.life }
        if #f.trail > 6 then table.remove(f.trail, 1) end
        f.x    = f.x + f.vx * dt
        f.y    = f.y + f.vy * dt
        f.vy   = f.vy + 90 * dt
        f.vx   = f.vx * (1 - 1.2 * dt)
        f.life = f.life - dt / f.max_life
        if f.life <= 0 then table.remove(fireworks, i) end
    end
end

function UpdateFloaters(dt)
    for i = #floaters, 1, -1 do
        local fl = floaters[i]
        fl.y     = fl.y + fl.vy * dt
        fl.life  = fl.life - dt / fl.max_life
        fl.scale = Lerp(fl.scale, 0.8, 4 * dt)
        if fl.life <= 0 then table.remove(floaters, i) end
    end
end

-- ═══════════════════════════════════════════════════════════
--  LOVE.DRAW
-- ═══════════════════════════════════════════════════════════
function love.draw()
    -- background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg_image,
        window.width / 2, window.height / 2, 0, 0.5, 0.5,
        bg_image:getWidth() / 2, bg_image:getHeight() / 2)

    -- ── top score (wavy letters) ──────────────────────────
    DrawWavyText(tostring(total_clicks * mult),
        points_text.x, points_text.y,
        points_font, ts.x, ts.y, global_timer)

    -- ── bottom: clicks × mult ─────────────────────────────
    love.graphics.setFont(points_font)
    love.graphics.setColor(1, 1, 1, 1)
    local full = total_clicks .. " x " .. mult
    -- gentle bob for mult text
    local bob_y = mult_text.y + math.sin(global_timer * 2.5) * 4
    love.graphics.print(full, mult_text.x, bob_y, 0, 1, 1,
        points_font:getWidth(full) / 2, points_font:getHeight() / 2)

    -- ── cookie shadow ────────────────────────────────────
    love.graphics.setColor(0.04, 0.04, 0.04, cookie_shadow_opacity)
    love.graphics.draw(cookie.sprite,
        cookie.x, cookie.y + 12,
        cookie.rotation, cookie.scale_x, cookie.scale_y,
        cookie.sprite:getWidth() / 2, cookie.sprite:getHeight() / 2)

    -- ── cookie ───────────────────────────────────────────
    -- subtle rainbow tint while hovered
    if cookie.hovered then
        local h = global_timer * 1.5
        love.graphics.setColor(
            0.85 + 0.15 * math.sin(h),
            0.85 + 0.15 * math.sin(h + 2.1),
            0.85 + 0.15 * math.sin(h + 4.2), 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.draw(cookie.sprite,
        cookie.x, cookie.y,
        cookie.rotation, cookie.scale_x, cookie.scale_y,
        cookie.sprite:getWidth() / 2, cookie.sprite:getHeight() / 2)

    -- ── shop panel ───────────────────────────────────────
    love.graphics.setColor(1, 1, 1, 1)
    local bg_scale_x = window.width / red_bg_image:getWidth()
    local bg_scale_y = shop.height / red_bg_image:getHeight()
    love.graphics.draw(red_bg_image, shop.x, shop.y, 0, bg_scale_x, bg_scale_y)

    -- hint text inside shop
    love.graphics.setFont(small_font)
    if shop_displayed and not can_click_card then
        love.graphics.setColor(1, 1, 0.2, 0.9 + 0.1 * math.sin(global_timer * 6))
        local hint = "Get ready..."
        love.graphics.print(hint, window.width / 2, shop.y + 18, 0, 1, 1,
            small_font:getWidth(hint) / 2, 0)
    elseif shop_displayed and can_click_card and anim_state == "idle" then
        love.graphics.setColor(1, 1, 1, 0.9 + 0.1 * math.sin(global_timer * 5))
        local hint = "✦ Pick a card! ✦"
        love.graphics.print(hint, window.width / 2, shop.y + 18, 0, 1, 1,
            small_font:getWidth(hint) / 2, 0)
    end

    -- ── non-selected cards ────────────────────────────────
    for i, card in ipairs(cards) do
        if card.visible and card ~= sel then
            -- hover highlight
            local mx, my = love.mouse.getPosition()
            local hovered = can_click_card
                and mx > card.left and mx < card.right
                and my > card.top and my < card.bottom
            if hovered then
                love.graphics.setColor(1, 1, 0.6, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.draw(card_image,
                card.x, card.y, card.rotation,
                card.scale_x * (hovered and 1.08 or 1),
                card.scale_y * (hovered and 1.08 or 1),
                card_image:getWidth() / 2, card_image:getHeight() / 2)
        end
    end

    -- ── selected card animation ───────────────────────────
    if sel and sel.visible then
        local card = sel
        if anim_state == "to_center"
            or anim_state == "flip_out"
            or anim_state == "flip_in" then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(card_image,
                card.ax, card.ay, 0,
                card.asx, card.asy,
                card_image:getWidth() / 2, card_image:getHeight() / 2)
        elseif anim_state == "show_result" then
            -- card background
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(card_image,
                card.ax, card.ay, 0,
                card.asx, card.asy,
                card_image:getWidth() / 2, card_image:getHeight() / 2)
            -- mult value — wavy & coloured
            local is_pos = card.mult >= 0
            if is_pos then
                love.graphics.setColor(0.15, 1, 0.3, 1)
            else
                love.graphics.setColor(1, 0.2, 0.2, 1)
            end
            love.graphics.setFont(points_font)
            local ms = (is_pos and "+" or "") .. tostring(card.mult)
            -- pulse scale
            local pulse = 1 + 0.08 * math.sin(global_timer * 10)
            love.graphics.print(ms, card.ax, card.ay - 10,
                0, pulse, pulse,
                points_font:getWidth(ms) / 2, points_font:getHeight() / 2)
        elseif anim_state == "travel" then
            love.graphics.setColor(1, 1, 1, card.asy / CARD_DISPLAY_SCALE)
            love.graphics.draw(card_image,
                card.ax, card.ay, 0,
                card.asx, card.asy,
                card_image:getWidth() / 2, card_image:getHeight() / 2)
        end
    end

    -- ── sparkle particles ─────────────────────────────────
    for _, p in ipairs(particles) do
        love.graphics.setColor(p.r, p.g, p.b, p.life)
        love.graphics.circle("fill", p.x, p.y, p.size * p.life)
    end

    -- ── fireworks ─────────────────────────────────────────
    for _, f in ipairs(fireworks) do
        -- trail
        for ti, tr in ipairs(f.trail) do
            local ta = tr.life * 0.3 * (ti / #f.trail)
            love.graphics.setColor(f.r, f.g, f.b, ta)
            love.graphics.circle("fill", tr.x, tr.y, f.size * 0.5 * tr.life)
        end
        love.graphics.setColor(f.r, f.g, f.b, f.life)
        love.graphics.circle("fill", f.x, f.y, f.size * f.life)
    end

    -- ── floating text ribbons ─────────────────────────────
    for _, fl in ipairs(floaters) do
        love.graphics.setFont(small_font)
        local a = fl.life
        love.graphics.setColor(fl.r, fl.g, fl.b, a)
        love.graphics.print(fl.text, fl.x, fl.y, 0,
            fl.scale, fl.scale,
            small_font:getWidth(fl.text) / 2,
            small_font:getHeight() / 2)
    end

    -- ── next milestone indicator (small, top-right) ───────
    if next_milestone_idx <= #milestones then
        love.graphics.setFont(tiny_font)
        love.graphics.setColor(1, 1, 0.4, 0.7)
        local ms_txt = "Next: " .. milestones[next_milestone_idx]
        love.graphics.print(ms_txt, window.width - 10, 10, 0, 1, 1,
            tiny_font:getWidth(ms_txt), 0)
    end
end

-- ═══════════════════════════════════════════════════════════
--  WAVY TEXT HELPER
-- ═══════════════════════════════════════════════════════════
function DrawWavyText(str, cx, cy, font, sx, sy, t)
    love.graphics.setFont(font)
    local total_w = font:getWidth(str) * sx
    local start_x = cx - total_w / 2
    local char_w  = font:getWidth("0") -- mono estimate
    for i = 1, #str do
        local ch    = str:sub(i, i)
        local xoff  = (i - 1) * font:getWidth(ch) * sx
        local ywave = math.sin(t * 3 + i * 0.6) * 6
        -- colour cycle
        local hh    = t * 0.3 + i * 0.15
        love.graphics.setColor(
            0.85 + 0.15 * math.sin(hh),
            0.85 + 0.15 * math.sin(hh + 2.1),
            0.85 + 0.15 * math.sin(hh + 4.2), 1)
        love.graphics.print(ch,
            start_x + xoff,
            cy + ywave,
            0, sx, sy, 0, font:getHeight() / 2)
    end
end

-- ═══════════════════════════════════════════════════════════
--  CARD HELPERS
-- ═══════════════════════════════════════════════════════════
function PositionCards()
    -- 2×2 grid well inside the shop, with generous vertical spacing
    local top_margin = 70 -- below the hint text
    local row_h      = (shop.height - top_margin) / 2
    local col_w      = shop.width / 2

    cards[1].x       = shop.x + col_w * 0.5
    cards[2].x       = shop.x + col_w * 1.5
    cards[3].x       = shop.x + col_w * 0.5
    cards[4].x       = shop.x + col_w * 1.5

    cards[1].y       = shop.y + top_margin + row_h * 0.38
    cards[2].y       = shop.y + top_margin + row_h * 0.38
    cards[3].y       = shop.y + top_margin + row_h * 1.38
    cards[4].y       = shop.y + top_margin + row_h * 1.38
end

function CalculateCardCollisionBox()
    for _, card in ipairs(cards) do
        local hw    = card_image:getWidth() * card.scale_x / 2
        local hh    = card_image:getHeight() * card.scale_y / 2
        card.left   = card.x - hw; card.right = card.x + hw
        card.top    = card.y - hh; card.bottom = card.y + hh
    end
end

function RotateCards(dt)
    card_rotation_timer = card_rotation_timer + dt
    for _, card in ipairs(cards) do
        if card ~= sel then
            card.rotation = math.sin(card_rotation_timer * 2 + card.rotation_offset) * 0.08
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  SHOP TRIGGER
-- ═══════════════════════════════════════════════════════════
function CheckCurrentPoints()
    if total_clicks * mult >= next_shop_threshold then
        OpenShop()
    end
end

function OpenShop()
    shop_displayed      = true
    can_click_card      = false
    shop_wait_timer     = 0
    shop_visit_count    = shop_visit_count + 1

    -- schedule thresholds: 100, 250, 450, 700, 1000 …
    local increment     = 100 + shop_visit_count * 50
    next_shop_threshold = next_shop_threshold + increment

    -- increase card mult range
    card_mult_factor    = card_mult_factor + math.random(1, 3)

    InitCards()
    PositionCards()
    -- // SOUND EFFECT: play a "shop curtain rises / fanfare" sound here
end

-- ═══════════════════════════════════════════════════════════
--  INPUT
-- ═══════════════════════════════════════════════════════════
function CheckCookieHovered()
    local mx, my = love.mouse.getPosition()
    cookie.hovered = mx > cookie.left and mx < cookie.right
        and my > cookie.top and my < cookie.bottom
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end

    -- cookie click (only when no shop / animation active)
    if not shop_displayed and anim_state == "idle" then
        if mx > cookie.left and mx < cookie.right
            and my > cookie.top and my < cookie.bottom then
            total_clicks = total_clicks + 1
            cookie.pressed = true
            ts.pumped = true
            cookie_wobble_speed = cookie_wobble_speed + RandRange(-1.2, 1.2)
            SpawnSparkle(cookie.x, cookie.y, 6)
            -- // SOUND EFFECT: play a "cookie crunch / click" sound here
        end
    end

    -- card pick (shop open, waited 1 s, one pick only)
    if shop_displayed and can_click_card and anim_state == "idle" then
        for _, card in ipairs(cards) do
            if card.visible
                and mx > card.left and mx < card.right
                and my > card.top and my < card.bottom then
                -- begin animation; block further picks immediately
                sel            = card
                card.ax        = card.x
                card.ay        = card.y
                card.asx       = card.scale_x
                card.asy       = card.scale_y
                anim_state     = "to_center"
                anim_t         = 0
                can_click_card = false -- ← prevents 2nd pick
                -- hide other cards
                for _, other in ipairs(cards) do
                    if other ~= card then other.visible = false end
                end
                -- // SOUND EFFECT: play a "card pick / swipe" sound here
                break
            end
        end
    end
end

function love.mousereleased(mx, my, button)
    if button == 1 and cookie.pressed then
        cookie.pressed = false
        ts.pumped = false
        -- // SOUND EFFECT: play a "cookie release / soft pop" sound here
    end
end

-- ═══════════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════════
function Lerp(a, b, t) return a + (b - a) * t end
