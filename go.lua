sq_sz = 156
bsize = 13
spsq = sq_sz/(bsize-1)

csize = 0.9*spsq

rxm = platform.window:width()+5
rym = platform.window:height()+5

edgx = (rxm-sq_sz)/2
edgy = (rym-sq_sz)/2

function make_board()
    a={}
    for i=1, bsize*bsize do
        a[i]=0.
    end

    a[bsize*bsize+1]=1
    a[bsize*bsize+2]=-1
    a[bsize*bsize+3]=2

    return a
end

function deep_copy(a)
    local b = {}
    for _, v in pairs(a) do
        table.insert(b, v)
    end
    return b
end

function is_in(list, element)
    for _, v in pairs(list) do
        if v==element then
            return true
        end
    end
    return false
end

function count_liberties(boa, field, note_table, liberties)
    local colr, fu, fr, fd, fl
    colr = boa[field]

    local col, row

    col = (field-1) % bsize
    row = math.floor((field-col-1) / bsize + 0.5)

    if (row~=0) then fu = (row-1)*bsize+col+1 else fu = bsize*bsize+3 end
    if (col~=bsize-1) then fr = row*bsize+col+2 else fr = bsize*bsize+3 end
    if (row~=bsize-1) then fd = (row+1)*bsize+col+1 else fd = bsize*bsize+3 end
    if (col~=0) then fl = row*bsize+col else fl = bsize*bsize+3 end

    local neightbours, mf

    neightbours = {fu, fr, fd, fl}

    for i=1, 4 do
        mf = neightbours[i]

        if (boa[mf] == 0) and (not is_in(liberties, mf)) then
            table.insert(liberties, mf)
        end
        if (boa[mf] == colr) and (not is_in(note_table, mf)) then
            table.insert(note_table, mf)
            liberties = count_liberties(boa, mf, note_table, liberties)
        end
    end
    return liberties
end

function is_legal(boa, ind)
    if (boa[ind]~=0) then
        return false
    end

    boa[ind] = boa[bsize*bsize+1]

    local removals = {}

    for i=1, bsize*bsize do
        if boa[i]~=0 then
            if (i ~= ind) and (#count_liberties(boa, i, {}, {})==0) then
                table.insert(removals, {i, boa[i]})
            end
        end
    end

    for _, val in pairs(removals) do
        boa[val[1]] = 0
    end

    new_libs = #count_liberties(boa, ind, {}, {})

    local repetions = true
    local turn
    if boa[bsize*bsize+1] == 1 then turn=2 else turn=1 end

    for i=1, bsize*bsize do
        if boa[i] ~= previous_states[turn][i] then
            repetions = false
            break
        end
    end

    boa[ind] = 0

    for _, val in pairs(removals) do
        boa[val[1]] = val[2]
    end

    if (new_libs == 0) or (repetions) then
        return false
    end
    
    return true
end

board = make_board()
previous_states = {{}, {}}

function on.paint(gc)
    gc:setColorRGB(240,220,180)
    gc:fillRect(edgx-10, edgy-10, sq_sz+20, sq_sz+20);

    gc:setColorRGB(0,0,0)

    local x,y
    
    y=edgy
    
    for row=1, (bsize-1) do
        x=edgx
        for col=1, (bsize-1) do
            gc:drawRect(x, y, spsq, spsq)
            x=x+spsq
        end
        y=y+spsq
    end

    for field=1, bsize*bsize do
        if board[field]~=0 then
            local col, row
            col=(field-1)%bsize
            row=math.floor((field-col-1)/bsize+0.5)

            if board[field]==-1 then
                gc:setColorRGB(255, 255, 255)
            else
                gc:setColorRGB(0, 0, 0)
            end

            gc:fillArc(col*spsq+edgx-csize/2, row*spsq +edgy-csize/2, csize, csize, 0, 360)
        end
    end

    if board[bsize*bsize+1]==-1 then
        gc:setColorRGB(255, 255, 255)
    else
        gc:setColorRGB(0, 0, 0)
    end

    local fd, fx, fy
    fd = board[bsize*bsize+2]

    if fd==-1 then
        return
    end

    fx = (fd-1)%bsize
    fy = math.floor((fd-fx-1)/bsize+0.5)

    gc:drawArc(spsq*fx+edgx-0.3*csize, spsq*fy+edgy-0.3*csize, 0.6*csize, 0.6*csize, 0, 360)
end

function on.mouseDown(x, y)
    if (x<edgx-5 or x > rxm-edgx+5) or (y<edgy-5 or y > rym-edgy+5) then
        return
    end
    local col, f, row

    col, row = math.floor((x-edgx)/spsq+0.5), math.floor((y-edgy)/spsq+0.5)
    f=bsize*row+col

    if not is_legal(board, f+1) then
        return
    end

    board[f+1]=board[bsize*bsize+1]
    board[bsize*bsize+1]=-board[bsize*bsize+1]
    board[bsize*bsize+2]=f+1

    local removals = {}

    for field=1, bsize*bsize do
        if board[field]~=0 then
            if (#count_liberties(board, field, {}, {})==0) and (field~=board[bsize*bsize+2]) then
                table.insert(removals, field)
            end
        end
    end

    for _, val in pairs(removals) do
        board[val] = 0
    end

    if board[bsize*bsize+1] == 1 then
        previous_states[1] = deep_copy(board)
    else
        previous_states[2] = deep_copy(board)
    end
    
    platform.window:invalidate(0, 0, rxm, rym)
end