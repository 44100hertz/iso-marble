(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

;; DEBUG ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn _G.pp [x] (print (fennel.view x)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require :src.lib.util) ;; creates global util.x
(require :src.lib.Vec) ;; creates global Vec2 and Vec3

(var call-table {}) ;; set of utility functions passed in as second argument of
                 ;; mode calls

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

(fn love.keypressed [_k scancode]
  (let [modifier-list {:ctrl ["lctrl" "rctrl" "capslock"]
                       :shift ["lshift" "rshift"]
                       :alt ["lalt" "ralt"]}
        modifiers (collect [modifier keys (pairs modifier-list)]
                           (values modifier (love.keyboard.isDown (unpack keys))))]
    (if (and modifiers.ctrl (= scancode "q"))
        (love.event.quit)
      (mode:keypressed scancode modifiers))))

(fn love.mousepressed [...]
 (when mode.mousepressed
   (mode:mousepressed ...)))

(fn love.mousemoved [...]
 (when mode.mousemoved
   (mode:mousemoved ...)))

(fn love.mousereleased [...]
 (when mode.mousereleased
   (mode:mousereleased ...)))

(fn love.wheelmoved [...]
 (when mode.wheelmoved
   (mode:wheelmoved ...)))
