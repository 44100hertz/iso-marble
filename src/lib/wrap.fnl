(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

;; DEBUG ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn _G.pp [x] (print (fennel.view x)))
(local pp _G.pp)

(set _G.DEBUG {
               :tiles true
               :editor-add-object false
               :editor-mouse-select false
               :render-object false
               :ui-position false})

(fn _G.DEBUG.info [...]
  (each [_ msg (ipairs [...])]
    (pp msg)))
(fn _G.DEBUG.warn-with-traceback [...]
  (each [_ msg (ipairs [...])]
    (pp msg))
  (print (debug.traceback)))
;;
;; UNCOMMENT TO DISABLE DEBUG
;; (set _G.DEBUG {})
;; (fn _G.DEBUG.warn [] (do))
;; /UNCOMMENT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require :src.lib.util) ;; creates global util.x
(require :src.lib.Vec) ;; creates global Vec2 and Vec3

(var call-table {}) ;; set of utility functions passed in as second argument of
                    ;; scene calls for the constructor, update, and draw

;; set the first scene
(var (scene scene-name) nil)

(fn set-scene [new-scene-name ...]
  (when (?. scene :destructor) (pcall scene.destructor scene ...))
  (set scene ((require new-scene-name) call-table ...))
  (set scene-name new-scene-name))

(fn love.load [args]
  (love.graphics.setDefaultFilter :nearest :nearest)
  (set call-table {: set-scene})
  (set-scene :src.editor.Editor "test")
  (when (~= :web (. args 1)) (repl.start)))

(fn love.draw []
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (scene:draw call-table))

(fn love.update [dt]
  (when scene.update
    (scene:update (_G.util.union {: dt} call-table))))

;; Try to handle an event using a list of handlers, which are objects (class
;; instances) containing methods with the same name and args as the event in
;; question. If said function does not exist, or the function returns false,
;; then try the next handler in the list.
(fn event-with-bubble [event args handlers]
  (var stop false)
  (each [_i handler (ipairs handlers) &until stop]
    (set stop (and (. handler event) ((. handler event) handler (unpack args))))))

;; When an event occurs, first check if the scene has a list of event handlers,
;; and bubble the event thru the handlers. If there are no event handlers, then
;; it will simply call the function on the scene, if it exists.
(fn handle-event [event-name ...]
  (if scene.event-handlers (event-with-bubble event-name [...] scene.event-handlers)
      (. scene event-name) ((. scene event-name) scene ...)))

;; Handle all basic events without transforming the input args
(local basic-events {:mousepressed true
                     :mousemoved true
                     :mousereleased true
                     :wheelmoved true})
(each [event-name handle-type (pairs basic-events)]
  (tset love event-name (partial handle-event event-name)))

;; Special event for keypressed -- collects modifier state and checks for ctrl+q
;; to quit
(fn love.keypressed [_k scancode is-repeat?]
 (let [modifier-list {:ctrl ["lctrl" "rctrl" "capslock"]
                      :shift ["lshift" "rshift"]
                      :alt ["lalt" "ralt"]}
       modifiers (collect [modifier keys (pairs modifier-list)]
                       (values modifier (love.keyboard.isDown (unpack keys))))]
   (if (and modifiers.ctrl (= scancode "q"))
      (love.event.quit)
      (handle-event :keypressed scancode modifiers is-repeat?))))
