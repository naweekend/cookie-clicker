local window = {}
local cookie = {}
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
local cards = {
    {
        mult = math.random(20),
        x = 0,
        y = 0,
        width = 9 * 15,
        height = 16 * 15,
    },
    {
        mult = math.random(20),
        x = 0,
        y = 0,
        width = 9 * 15,
        height = 16 * 15,
    },
    {
        mult = math.random(20),
        x = 0,
        y = 0,
        width = 9 * 15,
        height = 16 * 15,
    },
    {
        mult = math.random(20),
        x = 0,
        y = 0,
        width = 9 * 15,
        height = 16 * 15,
    },

}

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
    shop.height = 0.7 * window.height

    -- cards
end

function love.update(dt)
    if not shop_displayed then
        CheckCookieHovered()
    end
    -- hovering and clicking to scale logic
    if not shop_displayed and cookie.hovered then
        love.mouse.setCursor(cookie.cursor_pointer)

        cookie.scale_x = Lerp(cookie.scale_x, cookie.hover_scale, cookie.hover_scale_speed * dt)
        cookie.scale_y = Lerp(cookie.scale_y, cookie.hover_scale, cookie.hover_scale_speed * dt)
    else
        love.mouse.setCursor(cookie.cursor_default)

        cookie.scale_x = Lerp(cookie.scale_x, cookie.base_scale, cookie.hover_scale_speed * dt)
        cookie.scale_y = Lerp(cookie.scale_y, cookie.base_scale, cookie.hover_scale_speed * dt)
    end
    -- check points for shop every frame
    CheckCurrentPoints(dt)
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
        0, 1, 1,
        points_font:getWidth(total_clicks * mult) / 2,
        points_font:getHeight(total_clicks * mult) / 2
    )
    -- bottom ui box
    love.graphics.setColor(9 / 255, 36 / 255, 118 / 255, 0.8)
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
    love.graphics.setColor(9 / 255, 36 / 255, 118 / 255)
    love.graphics.rectangle(
        "fill",
        shop.x,
        shop.y,
        shop.width,
        shop.height
    )
    love.graphics.setColor(1, 1, 1, 1)
    -- add cards to shop
    for i, random_mult in ipairs(random_mults) do
        love.graphics.rectangle(
            "fill",
            shop.x * 0.2 * i,
            shop.y,
            card.width,
            card.height
        )
    end
end

function PositionCards()
    cards[1].x = shop.height
end

function CheckCurrentPoints(dt)
    local points = total_clicks * mult
    if points > 0 and points % 10 == 0 then
        DisplayShop(dt)
        shop_displayed = true
    end
end

function DisplayShop(dt)
    shop.y = Lerp(shop.y, 0.3 * window.height, 10 * dt)
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
        end
    end
end

-- mouse released checl
function love.mousereleased(mouse_x, mouse_y, button)
    if button == 1 then
        if cookie.pressed then
            print("cookie released")
            cookie.pressed = false
        end
    end
end

function Lerp(a, b, t)
    return a + (b - a) * t
end
