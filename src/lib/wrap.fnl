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

;; set the first mode
(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (when (?. mode :destructor) (pcall mode.destructor mode ...))
  (set mode ((require new-mode-name) ...))
  (set mode-name new-mode-name))

(fn love.load [args]
  (love.graphics.setDefaultFilter :nearest :nearest)
  (set-mode :src.editor.editor "test")
  (set screen-size (let [(x y) (love.window.getMode)]
                     {:x (/ x scale) :y (/ y scale)}))
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode "src.lib.error-mode" mode-name $ (fennel.traceback))))

(fn love.draw []
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (love.graphics.scale scale)
  (safely #(mode:draw {: screen-size})))

(fn love.update [dt]
  (when mode.update
    (safely #(mode:update {: dt : set-mode : screen-size}))))

(fn love.keypressed [_k scancode is-repeat]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= scancode "q"))
      (love.event.quit)
      ;; add what each keypress should do in each mode
      (safely #(mode:keypressed scancode is-repeat))))

(fn love.mousepressed [x y ...]
 (when mode.mousepressed
   (safely #mode.mousepressed (/ x scale) (/ y scale) ...)))
