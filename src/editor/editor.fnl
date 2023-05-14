(var Editor (util.class))

(import-macros {: ++} :src.lib.macros)
(local LevelMap (require :src.LevelMap))

(fn Editor.constructor [levelname]
  (love.keyboard.setKeyRepeat true)
  {:map (LevelMap levelname)
   :layer-index 1
   :layer-select-image (love.graphics.newImage "src/editor/layerselect.png")
   :scroll (Vec2 80 0)
   :scroll-rate 8})

(fn Editor.destructor []
  (love.keyboard.setKeyRepeat false))

;; Perform function f with a scrolling offset. If x and y are not specified, it
;; will use the editor's current scroll.
(fn Editor.with-scroll [self f]
  (util.with-scroll self.scroll f))

(fn Editor.set-layer [self layer]
  (set self.layer-index (util.clamp layer 1 (length self.map.layers))))

(fn Editor.set-layer-relative [self amount]
  (self:set-layer (+ self.layer-index amount)))

(set Editor.key-binds
  (let [set-scroll
        (fn [self offset is-shifted]
          (set self.scroll (+ self.scroll
                              (* (Vec2 self.scroll-rate)
                                 offset
                                 (Vec2 (if is-shifted 8 1))))))]
    {:q (fn [self] (self:set-layer-relative -1))
     :a (fn [self] (self:set-layer-relative 1))
     :up (fn [self modifiers] (set-scroll self (Vec2 0 1) modifiers.shift))
     :down (fn [self modifiers] (set-scroll self (Vec2 0 -1) modifiers.shift))
     :left (fn [self modifiers] (set-scroll self (Vec2 1 0) modifiers.shift))
     :right (fn [self modifiers] (set-scroll self (Vec2 -1 0) modifiers.shift))}))

(fn Editor.draw-map [self screen-size]
  (for [i (length self.map.layers) 1 -1]
    (when (= i self.layer-index)
      (util.with-color-rgba 1 0 0 0.2
        #(love.graphics.rectangle :fill 0 0 screen-size.x screen-size.y)))
    (self:with-scroll #(self.map:draw-layer i))))

(fn Editor.draw [self {: screen-size}]
  ;; draw map
  (self:draw-map screen-size)
  ;; draw UI
;;  (love.graphics.print self.layer-index)
  (love.graphics.draw self.layer-select-image 0 0))

(fn Editor.update [self])

(fn Editor.keypressed [self scancode modifiers]
  (when (. self.key-binds scancode) ((. self.key-binds scancode) self modifiers)))

(fn Editor.mousepressed [x y])

Editor
