local window = {}
local cookie = {}
local show_cookie_shadow = true
local cookie_shadow_opacity = 0.8
local base_cookie_shadow_opacity = 0.8
local bg_image
local points_font
local top_ui_box = {}
local points_text = {}
local total_clicks = 0
local mult = 1
local bottom_ui_box = {}
local mult_text = {}
local shop = {}
local shop_displayed = false
local card_mult_increasing_factor = 1
local cards = {
    {
        mult = math.random(-20, 20) * card_mult_increasing_factor,
        x = 0,
        y = 0,
        rotation = 0,
        rotation_offset = math.random(-10, 10),
        scale_x = 0.5,
    },
    {
        mult = math.random(-20, 20) * card_mult_increasing_factor,
        x = 0,
        y = 0,
        rotation = 0,
        rotation_offset = math.random(-10, 10),
        scale_x = 0.5,
    },
    {
        mult = math.random(-20, 20) * card_mult_increasing_factor,
        x = 0,
        y = 0,
        rotation = 0,
        rotation_offset = math.random(-10, 10),
        scale_x = 0.5,
    },
    {
        mult = math.random(-20, 20) * card_mult_increasing_factor,
        x = 0,
        y = 0,
        rotation = 0,
        rotation_offset = math.random(-10, 10),
        scale_x = 0.5,
    },
}
local text_scales = {}
local red_bg_image
local card_image
local card_rotation_timer = 0
local animate_card_to_center = false
local card_to_animate
local shop_wait_timer = 0
local can_click_card = false

function love.load()
    -- window width and height
    window.width = love.graphics.getWidth()
    window.height = love.graphics.getHeight()

    -- cookie
    cookie.sprite = love.graphics.newImage("images/cookie.png")
    cookie.x = 0
    cookie.y = 0
    cookie.rotation = 0
    cookie.scale_x = 0.5
    cookie.scale_y = 0.5
    cookie.scaled_width = cookie.sprite:getHeight() * cookie.scale_x
    cookie.scaled_height = cookie.sprite:getHeight() * cookie.scale_y
    -- update cookies x and y to center it
    cookie.x = (window.width) / 2
    cookie.y = (window.height) / 2
    cookie.base_y = (window.height) / 2
    cookie.shadow_y = (window.height) / 2 + 10
    cookie.pressed = false
    cookie.hovered = false
    cookie.base_scale = 0.5
    cookie.hover_scale = 0.55
    cookie.hover_scale_speed = 20
    cookie.width = cookie.sprite:getWidth()
    cookie.height = cookie.sprite:getHeight()
    cookie.left = cookie.x - (cookie.scaled_width / 2)
    cookie.right = cookie.x + (cookie.scaled_width / 2)
    cookie.top = cookie.y - (cookie.scaled_height / 2)
    cookie.bottom = cookie.y + (cookie.scaled_height / 2)
    cookie.cursor_default = love.mouse.getSystemCursor("arrow")
    cookie.cursor_pointer = love.mouse.getSystemCursor("hand")

    -- background image
    bg_image = love.graphics.newImage("images/background.jpg")

    -- fonts
    points_font = love.graphics.newFont("fonts/mightysouly.ttf", 80)

    -- top ui box
    top_ui_box.x = 0
    top_ui_box.y = 50
    top_ui_box.width = window.width
    top_ui_box.height = 100

    -- points text
    points_text.x = window.width / 2
    points_text.y = (top_ui_box.y + top_ui_box.height / 2)

    -- bottom ui box
    bottom_ui_box.x = 0
    bottom_ui_box.y = window.height - 150
    bottom_ui_box.width = window.width
    bottom_ui_box.height = 150

    -- mult text
    mult_text.x = window.width / 2
    mult_text.y = (bottom_ui_box.y + bottom_ui_box.height / 2)

    -- shop
    shop.x = 0
    shop.y = window.height
    shop.width = window.width
    shop.height = 0.8 * window.height

    -- cards
    -- card image
    card_image = love.graphics.newImage("images/card.png")
    PositionCards()

    -- text opacities
    text_scales.points_text_x = 1
    text_scales.points_text_y = 1
    text_scales.base_points_text_x = 1
    text_scales.base_points_text_y = 1
    text_scales.increased_points_text_x = 1.5
    text_scales.increased_points_text_y = 1.5
    text_scales.points_text_increased = false

    -- red background
    red_bg_image = love.graphics.newImage("images/red-background.jpg")
end

function love.update(dt)
    if not shop_displayed then
        CheckCookieHovered()
    end
    -- hovering cursor logic
    if not shop_displayed and cookie.hovered then
        love.mouse.setCursor(cookie.cursor_pointer)

        cookie.scale_x = Lerp(cookie.scale_x, cookie.hover_scale, cookie.hover_scale_speed * dt)
        cookie.scale_y = Lerp(cookie.scale_y, cookie.hover_scale, cookie.hover_scale_speed * dt)
    else
        love.mouse.setCursor(cookie.cursor_default)

        cookie.scale_x = Lerp(cookie.scale_x, cookie.base_scale, cookie.hover_scale_speed * dt)
        cookie.scale_y = Lerp(cookie.scale_y, cookie.base_scale, cookie.hover_scale_speed * dt)
    end
    -- clicking shadow logic
    if cookie.pressed then
        cookie.y = Lerp(cookie.y, cookie.shadow_y, 10 * dt)
        cookie_shadow_opacity = Lerp(cookie_shadow_opacity, 0, 10 * dt)
    else
        cookie.y = Lerp(cookie.y, cookie.base_y, 10 * dt)
        cookie_shadow_opacity = Lerp(cookie_shadow_opacity, base_cookie_shadow_opacity, 10 * dt)
    end
    -- check points for shop every frame
    CheckCurrentPoints(dt)
    -- point text scales
    if text_scales.points_text_increased then
        text_scales.points_text_x = Lerp(text_scales.points_text_x, text_scales.increased_points_text_x, 100 * dt)
        text_scales.points_text_y = Lerp(text_scales.points_text_y, text_scales.increased_points_text_y, 100 * dt)
    else
        text_scales.points_text_x = Lerp(text_scales.points_text_x, text_scales.base_points_text_x, 100 * dt)
        text_scales.points_text_y = Lerp(text_scales.points_text_y, text_scales.base_points_text_y, 100 * dt)
    end

    -- hide shop
    if not shop_displayed then
        HideShop(dt)
    end
    -- shop wait logic
    if shop_displayed then
        shop_wait_timer = shop_wait_timer + dt
        if shop_wait_timer >= 2 then
            can_click_card = true
        end
    end
    -- position cards
    PositionCards()
    -- update cards rotation
    RotateCards(dt)
    -- calculate card boundaries
    CalculateCardCollisionBox()
    -- animate cards to center
    if animate_card_to_center then
        AnimateCardToCenter(dt, card_to_animate)
    end
end

function love.draw()
    -- x, y, rotation in radians, scalex, scaley, originxoffset, originyoffset
    -- bg image
    love.graphics.draw(
        bg_image, window.width / 2, window.height / 2, 0, 0.5, 0.5, bg_image:getWidth() / 2, bg_image:getHeight() / 2
    )
    -- top ui box
    love.graphics.setFont(points_font)
    love.graphics.setColor(9 / 255, 36 / 255, 118 / 255, 0)
    love.graphics.rectangle("fill", top_ui_box.x, top_ui_box.y, top_ui_box.width, top_ui_box.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
        total_clicks * mult,
        points_text.x,
        points_text.y,
        0, text_scales.points_text_x, text_scales.points_text_y,
        points_font:getWidth(total_clicks * mult) / 2,
        points_font:getHeight(total_clicks * mult) / 2
    )
    -- bottom ui box
    love.graphics.setColor(255 / 255, 255 / 255, 255 / 255, 0)
    love.graphics.rectangle("fill", bottom_ui_box.x, bottom_ui_box.y, bottom_ui_box.width, bottom_ui_box.height)
    love.graphics.setColor(1, 1, 1, 1)
    local full_text = total_clicks .. " x " .. mult
    love.graphics.print(
        full_text,
        mult_text.x,
        mult_text.y,
        0, 1, 1,
        points_font:getWidth(full_text) / 2,
        points_font:getHeight(full_text) / 2
    )
    -- cookie shadow
    love.graphics.setColor(10 / 255, 10 / 255, 10 / 255, cookie_shadow_opacity)
    love.graphics.draw(
        cookie.sprite,
        cookie.x,
        cookie.y + 10,
        cookie.rotation,
        cookie.scale_x,
        cookie.scale_y,
        cookie.sprite:getWidth() / 2,
        cookie.sprite:getHeight() / 2
    )
    -- cookie
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        cookie.sprite,
        cookie.x,
        cookie.y,
        cookie.rotation,
        cookie.scale_x,
        cookie.scale_y,
        cookie.sprite:getWidth() / 2,
        cookie.sprite:getHeight() / 2
    )
    -- shop
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(red_bg_image, shop.x, shop.y, 0, 0.5, 0.5)

    -- add cards to shop
    for i, card in ipairs(cards) do
        love.graphics.draw(card_image, card.x, card.y, card.rotation, card.scale_x, 0.5, card_image:getWidth() / 2,
            card_image:getHeight() / 2, 0, 0)
    end
end

function PositionCards()
    card_height = card_image:getHeight()
    card_width = card_image:getWidth()

    -- x values
    cards[1].x = shop.width * 0.1 + card_width / 4
    cards[2].x = shop.width * 0.55 + card_width / 4
    cards[3].x = shop.width * 0.1 + card_width / 4
    cards[4].x = shop.width * 0.55 + card_width / 4
    -- y values
    cards[1].y = shop.y + shop.height * 0.03 + card_height / 4
    cards[2].y = shop.y + shop.height * 0.475 + card_height / 4
    cards[3].y = shop.y + shop.height * 0.475 + card_height / 4
    cards[4].y = shop.y + shop.height * 0.03 + card_height / 4
end

function CalculateCardCollisionBox()
    for i, card in ipairs(cards) do
        card.left = card.x - card_image:getWidth() / 2
        card.right = card.x + card_image:getWidth() / 2
        card.top = card.y - card_image:getHeight() / 2
        card.bottom = card.y + card_image:getHeight() / 2
    end
end

function AnimateCardToCenter(dt, card)
    card.x = Lerp(card.x, 0, 10 * dt)
    card.y = Lerp(card.y, 0, 10 * dt)
    card.scale_x = Lerp(card.scale_x, 0, 10 * dt)
    -- animate_card_to_center = false
    shop_displayed = false
end

function RotateCards(dt)
    card_rotation_timer = card_rotation_timer + dt
    for i, card in ipairs(cards) do
        card.rotation = math.sin(card_rotation_timer * 2 + card.rotation_offset) * 0.1
    end
end

function CheckCurrentPoints(dt)
    local points = total_clicks * mult
    if points > 0 and points % 10 == 0 then
        DisplayShop(dt)
        card_mult_increasing_factor = card_mult_increasing_factor + math.random(1, 5)
        shop_displayed = true
    end
end

function DisplayShop(dt)
    shop.y = Lerp(shop.y, 0.3 * window.height, 10 * dt)
end

function HideShop(dt)
    shop.y = Lerp(shop.y, window.height, 10 * dt)
end

-- check cookie hover
function CheckCookieHovered()
    local mouse_x, mouse_y = love.mouse.getPosition()

    if mouse_x > cookie.left and mouse_x < cookie.right
        and mouse_y > cookie.top and mouse_y < cookie.bottom then
        -- print("cookie hovered")
        cookie.hovered = true
    else
        cookie.hovered = false
    end
end

-- mouse pressed check
function love.mousepressed(mouse_x, mouse_y, button)
    if button == 1 and not shop_displayed then
        if mouse_x > cookie.left and mouse_x < cookie.right
            and mouse_y > cookie.top and mouse_y < cookie.bottom then
            print("cookie clicked")
            total_clicks = total_clicks + 1
            print(total_clicks)
            cookie.pressed = true
            text_scales.points_text_increased = true
        end
    elseif shop_displayed and can_click_card then
        for i, card in ipairs(cards) do
            if mouse_x > card.left and mouse_x < card.right
                and mouse_y > card.top and mouse_y < card.bottom then
                print("Card clicked" .. i .. "x" .. card.mult)
                mult = mult + card.mult
                if mult < 1 then mult = 1 end
                can_click_card = false
                card_to_animate = card
                animate_card_to_center = true
            end
        end
    end
end

-- mouse released checl
function love.mousereleased(mouse_x, mouse_y, button)
    if button == 1 then
        if cookie.pressed then
            print("cookie released")
            cookie.pressed = false
            text_scales.points_text_increased = false
        end
    end
end

function Lerp(a, b, t)
    return a + (b - a) * t
end
