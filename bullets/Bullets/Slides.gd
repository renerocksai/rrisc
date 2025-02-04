tool
extends Node2D
"""
Container for presentation Slide nodes.
Controls the currently displayed Slide.
"""

const animation_speed_in: = 0.5
const animation_speed_out: = 50

export var skip_animation: = false
export var slide_number_start := 1
export var mouse_hide_timeout := 1.5

onready var laserpointer = $LaserPointer
onready var laserpointer2 = $LaserPointer2
onready var laserpointer3 = $LaserPointer3

var my_laserpointer
var my_draw_positions

onready var touchcontrols = $"../TouchControls"
onready var swipedetector = $"../SwipeDetector"
onready var mousehidetimer = $CursorAutoHideTimer
onready var canvas = $"../DrawLayer"

onready var playerdisplay = $playerdisplay
onready var connectDlg = $"../JoinDialog"
onready var helpDlg = $"../helpdialog"
onready var gotoDlg = $"../gotodialog"

var index_active: = 0 setget set_index_active

var slide_current
var slide_nodes = []

var laserpointer_size = 1
var drawmode = false
var keep_drawing = false

var multiplayer_mode = false

func _ready() -> void:
    my_laserpointer = laserpointer
    my_draw_positions = canvas.positions
    my_laserpointer.hide()
    for slide in get_children():
        if not slide is Slide:
            continue
        slide.hide()
        slide_nodes.append(slide)
    if Engine.editor_hint:
        set_process_unhandled_input(false)
    else:
        for slide in slide_nodes:
            remove_child(slide)
        remove_child(playerdisplay)
        playerdisplay.hide()
        
    # connect
    swipedetector.connect("silly_tap_release", touchcontrols, "flash_controls")
    mousehidetimer.connect("timeout", self, "_on_mousehide_timeout")
    mousehidetimer.wait_time = mouse_hide_timeout
    Server.connect("Change_Slide", self, "nw_change_slides")
    Server.connect("Connect_Failed", self, "nw_connect_failed")
    Server.connect("Room_Full", self, "nw_room_full")
    Server.connect("Update_Player", self, "nw_update_player")
    Server.connect("Introduce_Player", self, "nw_introduce_player")
    Server.connect("Unintroduce_Player", self, "nw_unintroduce_player")
    Server.connect("Welcome_Player", self, "nw_welcome")
    Server.connect("Remote_Click", self, "onRemoteClick")
    playerdisplay.connect("timeout", self, "playerdisplay_timeout")
    connectDlg.connect("join_server", self, "onJoinPressed")
    connectDlg.connect("canceled", self, "onCancelPressed")
    gotoDlg.connect("change_slide", self, "onChangeSlideSignal")


    if not Engine.editor_hint:
        # our own event system to allow things like audio buttons to emit
        # signals without us needing have a reference to them
        EventManager.listen('click', funcref(self, "sendRemoteClick"))
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func sendRemoteClick(nodePath: String):
    Server.send_click(nodePath)

func onRemoteClick(nodePath: String):
    var clickthing = get_node_or_null(nodePath)
    if clickthing == null:
        print('Error: cannot click on ', nodePath)
    else:
        clickthing._pressed(true)

func onChangeSlideSignal(slide_number):
    set_index_active(slide_number - 1)
    
func debug_log(what):
    var time = OS.get_ticks_msec()
    var seconds: int = time / 1000
    var milli = time - seconds * 1000
    print('%03d.%03d - %s' % [seconds, milli, what])

# Multiplayer info display
var playerdisplay_stack = []
func playerdisplay_show(what) -> void:
    debug_log('playerdisplay_show("%s")' % what)
    if playerdisplay.is_visible():
        debug_log('    (queued)')
        playerdisplay_stack.append(what)
    else:
        playerdisplay.bbcode_text = '[center]' + what
        debug_log('    displayed!')
        if not is_a_parent_of(playerdisplay):
            add_child(playerdisplay)
        playerdisplay.start()

func playerdisplay_timeout():
    debug_log('playerdisplay_timeout()')
    var next = playerdisplay_stack.pop_front()
    if next != null:
        playerdisplay.bbcode_text = '[center]' + next
        debug_log('    un-queued: %s' % next)
        playerdisplay.start()
    else:
        playerdisplay.hide()
        remove_child(playerdisplay)

### Server functions
func onJoinPressed(url, room_name):
    Server.start_multiplayer(url, room_name)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # no artifact cursor pls
    
func onCancelPressed():
    multiplayer_mode = false
    connectDlg.hide()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # no artifact cursor pls
    
func nw_change_slides(slide_number):
    set_index_active(slide_number, true)

func nw_welcome(player_number):
    if player_number == 0:
        my_laserpointer = laserpointer
        my_draw_positions = canvas.positions
    elif player_number == 1:
        my_laserpointer = laserpointer2
        my_draw_positions = canvas.positions_2
    elif player_number == 2:
        my_laserpointer = laserpointer3
        my_draw_positions = canvas.positions_3
    for other in [laserpointer, laserpointer2, laserpointer3]:
        if other != my_laserpointer:
            other.follow_mouse = false
    playerdisplay_show('You are\nPlayer %d' % (player_number + 1))

func nw_room_full():
    playerdisplay_show('Room full!')

func nw_connect_failed():
    playerdisplay_show('Connect failed')
    multiplayer_mode = false

func nw_update_player(player_number, pos, draw, laser):
    var affected_laserpointer
    if player_number == 0:
        affected_laserpointer = laserpointer
        canvas.positions = draw
    elif player_number == 1:
        affected_laserpointer = laserpointer2
        canvas.positions_2 = draw
    elif player_number == 2:
        affected_laserpointer = laserpointer3
        canvas.positions_3 = draw
    if laser['active']:
        affected_laserpointer.show()
    else:
        affected_laserpointer.hide()
    affected_laserpointer.position = pos
    affected_laserpointer.scale = laser['scale']
    canvas.update()

func nw_introduce_player(player_number, pos, draw, laser):
    print('introduce player', player_number)
    nw_update_player(player_number, pos, draw, laser)
    playerdisplay_show('Player %d\njoined!' % (player_number + 1))

func nw_unintroduce_player(player_number, pos, draw, laser):
    nw_update_player(player_number, pos, draw, laser)
    playerdisplay_show('Player %d\nleft!' % (player_number + 1))
### end of Server functions


func _on_mousehide_timeout():
    if not drawmode and not connectDlg.is_visible():
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _get_configuration_warning() -> String:
    return "%s needs Slide nodes as its children to work" % name if not slide_nodes else ""

var click_direction = 0

var presstime = 0

func _unhandled_input(event: InputEvent) -> void:
    var valid_event: bool = (
        event is InputEventMouseButton
        or event is InputEventMouseMotion
        or event.is_action('ui_accept')
        or event.is_action('ui_right')
        or event.is_action('ui_left')
        or event.is_action('ui_page_down')
        or event.is_action('ui_page_up')
        or event.is_action('quit')
        or event.is_action('to_png')
        or event.is_action('go_home')
        or event.is_action('toggle_laserpointer')
        or event.is_action('cycle_laserpointer_sizes')
        or event.is_action('toggle_drawmode')
        or event.is_action('clear_drawing')
        or event.is_action('input_multiplayer')
        or event.is_action("goto_slide")
        or event.is_action("goto_slide_1")
        or event.is_action("goto_last_slide")
    )
    if not valid_event:
        return

    if event.is_action_pressed('ui_right') or event.is_action_pressed('ui_accept') or event.is_action_pressed('ui_page_down'):
        self.index_active += 1
    elif event.is_action_pressed('ui_left')  or event.is_action_pressed('ui_page_up'):
        self.index_active -= 1
    elif event.is_action_pressed("goto_slide_1"):
        set_index_active(0)
    elif event.is_action_pressed("goto_last_slide"):
        set_index_active(1000)
    elif event.is_action('quit'):
        get_tree().quit()
    elif event.is_action_pressed('to_png'):
        save_as_png('.')
    elif event.is_action_pressed("goto_slide"):
        gotoDlg.popup_centered()
    elif event.is_action_pressed('go_home'):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        # get_tree().change_scene("res://Bullets/Slides/bootmenu.tscn")
        helpDlg.popup_centered()
    elif event.is_action_pressed('cycle_laserpointer_sizes'):
        laserpointer_size -= .25
        if laserpointer_size < .25:
            laserpointer_size = 1.0
        my_laserpointer.scale = Vector2(laserpointer_size, laserpointer_size)
    elif event.is_action_pressed('toggle_laserpointer'):
        if my_laserpointer.is_visible():
            my_laserpointer.hide()
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            my_laserpointer.set_visible(true)
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
        Server.send_update_player(my_laserpointer.position, my_draw_positions, {'active': my_laserpointer.is_visible(), 'scale': my_laserpointer.scale})
    elif event.is_action_pressed('toggle_drawmode'):
        drawmode = not drawmode
        if drawmode:
            touchcontrols.hide()
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            mousehidetimer.start()
            touchcontrols.show()
    elif event.is_action_pressed("clear_drawing"):
        canvas.clear(my_draw_positions)
        Server.send_update_player(my_laserpointer.position, my_draw_positions, {'active': my_laserpointer.is_visible(), 'scale': my_laserpointer.scale})
    elif event.is_action_pressed("input_multiplayer"):
        if not connectDlg.is_visible():
            multiplayer_mode = !multiplayer_mode
            if multiplayer_mode:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
                connectDlg.popup_centered()
            else:
                Server.stop_multiplayer()
                playerdisplay_show('Multiplayer: off')

    if event is InputEventMouseButton:
        if event.pressed:
            match event.button_index:
                BUTTON_LEFT:
                    if drawmode:
                        keep_drawing = true
                        canvas.draw(event.position, my_draw_positions)
                    else:
                        self.index_active += 1
                BUTTON_RIGHT:
                    self.index_active -= 1
        else:
            keep_drawing = false
            if drawmode:
                canvas.draw(Vector2.ZERO, my_draw_positions)

    # mouse pointer auto-hide
    if event is InputEventMouseMotion:
        if drawmode and keep_drawing:
            canvas.draw(event.position, my_draw_positions)
        if not Engine.editor_hint:
            mousehidetimer.start()
            if not my_laserpointer.is_visible():
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            if my_laserpointer.is_visible() or drawmode:
                Server.send_update_player(event.position, my_draw_positions, {'active': my_laserpointer.is_visible(), 'scale': my_laserpointer.scale})


func initialize() -> void:
    if not slide_nodes:
        return
    if OS.has_feature('JavaScript'):
        # this is bloody important! if left to true, screenshots will show wrong colors!!!
        get_viewport().set_hdr(false)
    _display(0)


func set_index_active(value : int, from_network=false) -> void:
    var index_previous: = index_active
    index_active = clamp(value, 0, max(slide_nodes.size() - 1, 0))
    if index_active != index_previous:
        _display(index_active)
    if multiplayer_mode and not from_network:
        Server.send_change_slide(index_active)


func download_pdf():
    skip_animation = true
    get_tree().paused = true
    get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
    var howmany = len(slide_nodes)
    JavaScript.eval('setMaxPage(%d);' % howmany)
    JavaScript.eval('startPdf();')
    for slide in slide_nodes:
        # Need to wait two frames to ensure the screen capture works
        yield(get_tree(), "idle_frame")
        yield(get_tree(), "idle_frame")

        var img: = get_viewport().get_texture().get_data()
        img.flip_y()
        img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
        var base64raw = Utils.Img2Base64(img)
        JavaScript.eval('addPage("%s")' % base64raw)
        self.index_active += 1
    get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
    get_tree().paused = false
    skip_animation = false


func save_as_png(output_folder: String) -> void:
    if OS.has_feature('JavaScript') or false:
        download_pdf()
        return
    skip_animation = true
    get_tree().paused = true
    get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
    var id: = 0
    for slide in slide_nodes:
        # Need to wait two frames to ensure the screen capture works
        yield(get_tree(), "idle_frame")
        yield(get_tree(), "idle_frame")

        var img: = get_viewport().get_texture().get_data()
        img.flip_y()
        var path: = output_folder.plus_file(str(id).pad_zeros(2) + '-' + slide.name + '.png')
        img.save_png(path)
        self.index_active += 1
        id += 1
    get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
    get_tree().paused = false
    skip_animation = false


func _display(slide_index : int) -> void:
    set_process_unhandled_input(false)
    var previous_slide = slide_current
    slide_current = slide_nodes[slide_index]

    if previous_slide == slide_current:
        set_process_unhandled_input(true)
        return

    slide_current.cancel_animation()

    if previous_slide and false:
        if previous_slide.play('FadeOut', animation_speed_out, skip_animation):
            if not skip_animation:
                yield(previous_slide, "animation_finished")

    add_child(slide_current)
    if is_a_parent_of(playerdisplay):
        remove_child(playerdisplay)
    add_child(playerdisplay)
    slide_current.visible = true
    slide_current.set_slide_number(slide_index + slide_number_start)

    if slide_current.play('FadeIn', animation_speed_in, skip_animation):
        if not skip_animation:
            yield(slide_current, "animation_finished")

    if previous_slide:
        remove_child(previous_slide)
    set_process_unhandled_input(true)

func alert(text: String, title: String='Message') -> void:
    var dialog = AcceptDialog.new()
    dialog.dialog_text = text
    dialog.window_title = title
    dialog.connect('modal_closed', dialog, 'queue_free')
    add_child(dialog)
    dialog.popup_centered()
