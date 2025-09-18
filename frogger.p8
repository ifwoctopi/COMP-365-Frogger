pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- frogger.p8
-- a classic frogger game for pico-8

-- game state constants
menu = 0
playing = 1
game_over = 2
paused = 3

-- game variables
game_state = menu
score = 0
lives = 3
level = 1
frog_x = 64
frog_y = 112
frog_target_x = 64
frog_target_y = 112
frog_speed = 8
frog_size = 4

-- car variables
cars = {}
car_speed = 1
car_spawn_timer = 0
car_spawn_delay = 60

-- log variables
logs = {}
log_speed = 0.5
log_spawn_timer = 0
log_spawn_delay = 90

-- water variables
water_y = 32
water_height = 32

-- home variables
homes = {}
home_y = 16
home_width = 16
home_height = 8

-- colors
bg_color = 0
frog_color = 11
car_color = 8
log_color = 6
water_color = 12
road_color = 5
grass_color = 3
home_color = 10

function _init()
    -- initialize homes
    for i = 0, 4 do
        add(homes, {x = i * 32 + 8, y = home_y, occupied = false})
    end
    
    -- initialize first car
    add_car()
end

function add_car()
    local direction = rnd(2) > 1 and 1 or -1
    local y = 80 + flr(rnd(3)) * 8
    add(cars, {
        x = direction > 0 and -16 or 128,
        y = y,
        width = 12,
        height = 6,
        speed = direction * (car_speed + level * 0.5),
        color = 8 + flr(rnd(3))
    })
end

function add_log()
    local direction = rnd(2) > 1 and 1 or -1
    local y = water_y + 8 + flr(rnd(3)) * 8
    add(logs, {
        x = direction > 0 and -24 or 128,
        y = y,
        width = 20,
        height = 8,
        speed = direction * (log_speed + level * 0.3)
    })
end

function update_frog()
    if game_state ~= playing then return end
    
    -- move frog towards target
    local dx = frog_target_x - frog_x
    local dy = frog_target_y - frog_y
    
    if abs(dx) > 1 then
        frog_x += sgn(dx) * frog_speed
    else
        frog_x = frog_target_x
    end
    
    if abs(dy) > 1 then
        frog_y += sgn(dy) * frog_speed
    else
        frog_y = frog_target_y
    end
    
    -- check if frog reached home
    for home in all(homes) do
        if not home.occupied and 
           frog_x >= home.x and frog_x <= home.x + home_width and
           frog_y >= home.y and frog_y <= home.y + home_height then
            home.occupied = true
            score += 100 * level
            level += 1
            reset_frog()
            car_speed += 0.2
            log_speed += 0.1
        end
    end
    
    -- check if all homes are occupied
    local all_occupied = true
    for home in all(homes) do
        if not home.occupied then
            all_occupied = false
            break
        end
    end
    
    if all_occupied then
        -- level complete
        for home in all(homes) do
            home.occupied = false
        end
        reset_frog()
    end
end

function reset_frog()
    frog_x = 64
    frog_y = 112
    frog_target_x = 64
    frog_target_y = 112
end

function check_collisions()
    if game_state ~= playing then return end
    
    -- check car collisions
    for car in all(cars) do
        if frog_x < car.x + car.width and
           frog_x + frog_size > car.x and
           frog_y < car.y + car.height and
           frog_y + frog_size > car.y then
            -- frog hit by car
            lives -= 1
            reset_frog()
            if lives <= 0 then
                game_state = game_over
            end
        end
    end
    
    -- check water collisions
    if frog_y >= water_y and frog_y < water_y + water_height then
        local on_log = false
        for log in all(logs) do
            if frog_x >= log.x and frog_x <= log.x + log.width and
               frog_y >= log.y and frog_y <= log.y + log.height then
                on_log = true
                -- move with log
                frog_x += log.speed
                frog_target_x += log.speed
                break
            end
        end
        
        if not on_log then
            -- frog in water without log
            lives -= 1
            reset_frog()
            if lives <= 0 then
                game_state = game_over
            end
        end
    end
    
    -- keep frog on screen
    if frog_x < 0 then frog_x = 0 frog_target_x = 0 end
    if frog_x > 120 then frog_x = 120 frog_target_x = 120 end
    if frog_y < 0 then frog_y = 0 frog_target_y = 0 end
    if frog_y > 120 then frog_y = 120 frog_target_y = 120 end
end

function update_cars()
    for car in all(cars) do
        car.x += car.speed
        
        -- remove cars that are off screen
        if car.x < -20 or car.x > 140 then
            del(cars, car)
        end
    end
    
    -- spawn new cars
    car_spawn_timer += 1
    if car_spawn_timer >= car_spawn_delay then
        add_car()
        car_spawn_timer = 0
    end
end

function update_logs()
    for log in all(logs) do
        log.x += log.speed
        
        -- remove logs that are off screen
        if log.x < -30 or log.x > 150 then
            del(logs, log)
        end
    end
    
    -- spawn new logs
    log_spawn_timer += 1
    if log_spawn_timer >= log_spawn_delay then
        add_log()
        log_spawn_timer = 0
    end
end

function _update()
    if game_state == menu then
        if btnp(5) then -- x button
            game_state = playing
        end
    elseif game_state == playing then
        -- handle input
        if btnp(0) and frog_y > 0 then -- left
            frog_target_x = max(0, frog_target_x - 16)
        elseif btnp(1) and frog_y > 0 then -- right
            frog_target_x = min(120, frog_target_x + 16)
        elseif btnp(2) and frog_y > 0 then -- up
            frog_target_y = max(0, frog_target_y - 16)
        elseif btnp(3) and frog_y < 120 then -- down
            frog_target_y = min(120, frog_target_y + 16)
        end
        
        if btnp(4) then -- o button
            game_state = paused
        end
        
        update_frog()
        update_cars()
        update_logs()
        check_collisions()
        
    elseif game_state == paused then
        if btnp(4) then -- o button
            game_state = playing
        end
        if btnp(5) then -- x button
            game_state = menu
        end
    elseif game_state == game_over then
        if btnp(5) then -- x button
            -- reset game
            game_state = menu
            score = 0
            lives = 3
            level = 1
            car_speed = 1
            log_speed = 0.5
            cars = {}
            logs = {}
            for home in all(homes) do
                home.occupied = false
            end
            reset_frog()
        end
    end
end

function draw_background()
    -- sky
    rectfill(0, 0, 127, 15, bg_color)
    
    -- water
    rectfill(0, water_y, 127, water_y + water_height, water_color)
    
    -- road
    rectfill(0, 80, 127, 95, road_color)
    
    -- grass
    rectfill(0, 96, 127, 111, grass_color)
    rectfill(0, 112, 127, 127, grass_color)
    
    -- road lines
    for i = 0, 7 do
        rectfill(i * 16, 87, i * 16 + 8, 88, 7)
    end
end

function draw_homes()
    for home in all(homes) do
        local color = home.occupied and 2 or home_color
        rectfill(home.x, home.y, home.x + home_width, home.y + home_height, color)
        rect(home.x, home.y, home.x + home_width, home.y + home_height, 0)
    end
end

function draw_frog()
    if game_state == playing or game_state == paused then
        spr(001,frog_x + 2, frog_y + 2)
        spr(001,frog_x + 2, frog_y + 2)
    end
end

function draw_cars()
    for car in all(cars) do
        rectfill(car.x, car.y, car.x + car.width, car.y + car.height, car.color)
        rect(car.x, car.y, car.x + car.width, car.y + car.height, 0)
    end
end

function draw_logs()
    for log in all(logs) do
        rectfill(log.x, log.y, log.x + log.width, log.y + log.height, log_color)
        rect(log.x, log.y, log.x + log.width, log.y + log.height, 0)
    end
end

function draw_ui()
    -- score
    print("score: " .. score, 2, 2, 7)
    print("lives: " .. lives, 2, 10, 7)
    print("level: " .. level, 100, 2, 7)
    
    if game_state == menu then
        print("frogger", 40, 50, 11)
        print("press x to start", 30, 60, 7)
    elseif game_state == paused then
        print("paused", 50, 60, 7)
        print("press o to resume", 30, 70, 7)
        print("press x for menu", 30, 80, 7)
    elseif game_state == game_over then
        print("game over", 40, 50, 8)
        print("final score: " .. score, 30, 60, 7)
        print("press x to restart", 25, 70, 7)
    end
end

function _draw()
    cls(bg_color)
    
    if game_state == playing or game_state == paused then
        draw_background()
        draw_homes()
        draw_logs()
        draw_cars()
        draw_frog()
    end
    
    draw_ui()
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700001707100037073000270720004707400027072000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000001ccc10003bbb30002eee2000499940002ddd2000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000c1c00000b3b00000e2e0000094900000d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700001ccc10003bbb30002eee2000499940002ddd2000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001000100030003000200020004000400020002000000000000000000000000000000000000000000000000000000000000000000000000000000000
