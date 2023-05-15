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

(var scale 4)
(var screen-size {})
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
  (set screen-size (let [(x y) (love.window.getMode)]
                     (_G.Vec2 (/ x scale) (/ y scale))))
  (set call-table {: set-mode : screen-size})
  (set-mode :src.editor.editor "test")
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
 (f))
;;  (xpcall f #(set-mode "src.lib.error-mode" mode-name $ (fennel.traceback))))

;; A table that is put into every call to mode so that it has more functionality

(fn love.draw []
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (love.graphics.scale scale)
  (safely #(mode:draw call-table)))

(fn love.update [dt]
  (when mode.update
    (safely #(mode:update (_G.util.union {: dt} call-table)))))

(fn love.keypressed [_k scancode]
  (let [modifier-list {:ctrl ["lctrl" "rctrl" "capslock"]
                       :shift ["lshift" "rshift"]
                       :alt ["lalt" "ralt"]}
        modifiers (collect [modifier keys (pairs modifier-list)]
                           (values modifier (love.keyboard.isDown (unpack keys))))]
    (if (and modifiers.ctrl (= scancode "q"))
        (love.event.quit)
      (safely #(mode:keypressed scancode modifiers)))))

(fn love.mousepressed [x y ...]
 (when mode.mousepressed
   (safely #(mode:mousepressed (/ x scale) (/ y scale) $...))))

(fn love.mousemoved [x y ...]
 (when mode.mousemoved
   (safely #(mode:mousemoved (/ x scale) (/ y scale) $...))))

(fn love.mousereleased [x y ...]
 (when mode.mousereleased
   (safely #(mode:mousereleased (/ x scale) (/ y scale) $...))))
