(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

(var scale 4)

;; set the first mode
(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (set (mode mode-name) (values (require new-mode-name) new-mode-name))
  (when mode.activate
    (match (pcall mode.activate ...)
      (false msg) (print mode-name "activate error" msg))))

(fn love.load [args]
  (love.graphics.setDefaultFilter :nearest :nearest)
  (set-mode "src/viewer/viewer")
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode "src/lib/error-mode" mode-name $ (fennel.traceback))))

(fn love.draw []
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (love.graphics.scale scale)
  (safely #(mode.draw mode)))

(fn love.update [dt]
  (when mode.update
    (safely #(mode.update dt set-mode))))

(fn love.keypressed [key]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
      (love.event.quit)
      ;; add what each keypress should do in each mode
      (safely #(mode.keypressed key set-mode))))
