(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

;; DEBUG ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn _G.pp [x] (print (fennel.view x)))
(local pp _G.pp)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require :src.lib.util) ;; creates global util.x
(require :src.lib.Vec) ;; creates global Vec2 and Vec3

(var call-table {}) ;; set of utility functions passed in as second argument of
                    ;; mode calls for the constructor, update, and draw

;; set the first mode
(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (when (?. mode :destructor) (pcall mode.destructor mode ...))
  (set mode ((require new-mode-name) call-table ...))
  (set mode-name new-mode-name))

(fn love.load [args]
  (love.graphics.setDefaultFilter :nearest :nearest)
  (set call-table {: set-mode})
  (set-mode :src.editor.editor "test")
  (when (~= :web (. args 1)) (repl.start)))

(fn love.draw []
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (mode:draw call-table))

(fn love.update [dt]
  (when mode.update
    (mode:update (_G.util.union {: dt} call-table))))

;; Try to handle an event using a list of handlers, which are objects (class
;; instances) containing methods with the same name and args as the event in
;; question. If said function does not exist, or the function returns false,
;; then try the next handler in the list.
(fn event-with-bubble [event args handlers handler-index]
  (let [handler-index (or handler-index 1)
        handler (. handlers handler-index)
        event-function (?. handler event)]
    (when handler
      (if (not (and event-function
                   (event-function handler (unpack args))))
        (event-with-bubble event args handlers (+ 1 handler-index))))))

;; When an event occurs, irst check if the mode has a list of event handlers,
;; and bubble the event thru the handlers. If there are no event handlers, then
;; it will simply call the function on the mode, if it exists.
(fn handle-event [event-name ...]
  (if mode.event-handlers (event-with-bubble event-name [...] mode.event-handlers)
      (. mode event-name) ((. mode event-name) mode ...)))

;; Handle all basic events without transforming the input args
(local basic-events {:mousepressed true
                     :mousemoved true
                     :mousereleased true
                     :wheelmoved true})
(each [event-name handle-type (pairs basic-events)]
  (tset love event-name (partial handle-event event-name)))

;; Special event for keypressed -- collects modifier state and checks for ctrl+q
;; to quit
(fn love.keypressed [_k scancode]
 (let [modifier-list {:ctrl ["lctrl" "rctrl" "capslock"]
                      :shift ["lshift" "rshift"]
                      :alt ["lalt" "ralt"]}
       modifiers (collect [modifier keys (pairs modifier-list)]
                       (values modifier (love.keyboard.isDown (unpack keys))))]
   (if (and modifiers.ctrl (= scancode "q"))
      (love.event.quit)
      (handle-event :keypressed scancode modifiers))))
