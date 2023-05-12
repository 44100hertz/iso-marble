(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))
(require :src.lib.util) ;; creates global util.x

;; DEBUG ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn _G.pp [x] (print (fennel.view x)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(var scale 4)
(var screen-size {})

;; set the first mode
(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (set (mode mode-name) (values (require new-mode-name) new-mode-name))
  (when mode.activate
    (match (pcall mode.activate mode ...)
      (false msg) (print mode-name "activate error" msg))))

(fn love.load [args]
  (love.graphics.setDefaultFilter :nearest :nearest)
  (set-mode "src.editor.editor")
  (set screen-size (let [(x y) (love.window.getMode)]
                     {:x (/ x scale) :y (/ y scale)}))
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode "src.lib.error-mode" mode-name $ (fennel.traceback))))

(fn love.draw []
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (love.graphics.scale scale)
  (safely #(mode.draw mode {: screen-size})))

(fn love.update [dt]
  (when mode.update
    (safely #(mode.update mode {: dt : set-mode : screen-size}))))

(fn love.keypressed [_k scancode]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= scancode "q"))
      (love.event.quit)
      ;; add what each keypress should do in each mode
      (safely #(mode.keypressed mode scancode))))

(fn love.mousepressed [x y ...]
 (when mode.mousepressed
   (safely #mode.mousepressed (/ x scale) (/ y scale) ...)))
