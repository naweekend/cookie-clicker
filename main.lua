local window = {}
local cookie = {}
local bgImage

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
    bgImage = love.graphics.newImage("images/background.jpg")
end

function love.update(dt)
    CheckCookieHovered()
    -- hovering and clicking to scale logic
    if cookie.hovered then
        love.mouse.setCursor(cookie.cursor_pointer)

        cookie.scale_x = Lerp(cookie.scale_x, cookie.hover_scale, cookie.hover_scale_speed * dt)
        cookie.scale_y = Lerp(cookie.scale_y, cookie.hover_scale, cookie.hover_scale_speed * dt)
    else
        love.mouse.setCursor(cookie.cursor_default)

        cookie.scale_x = Lerp(cookie.scale_x, cookie.base_scale, cookie.hover_scale_speed * dt)
        cookie.scale_y = Lerp(cookie.scale_y, cookie.base_scale, cookie.hover_scale_speed * dt)
    end
end

function love.draw()
    -- x, y, rotation radians, scalex, scaley, originxoffset, originyoffset
    love.graphics.draw(
        bgImage, 0, 0, 0
    )
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
end

-- check cookie hover
function CheckCookieHovered()
    local mouse_x, mouse_y = love.mouse.getPosition()

    if mouse_x > cookie.left and mouse_x < cookie.right
        and mouse_y > cookie.top and mouse_y < cookie.bottom then
        print("cookie hovered")
        cookie.hovered = true
    else
        cookie.hovered = false
    end
end

-- mouse pressed check
function love.mousepressed(mouse_x, mouse_y, button)
    if button == 1 then
        if mouse_x > cookie.left and mouse_x < cookie.right
            and mouse_y > cookie.top and mouse_y < cookie.bottom then
            print("cookie clicked")
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
