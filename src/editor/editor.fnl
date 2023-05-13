(var Editor (util.class))

(import-macros {: ++} :src.lib.macros)
(local LevelMap (require :src.LevelMap))

(fn Editor.constructor [levelname]
  {:map (LevelMap levelname)
   :layer-index 1
   :layer-select-image (love.graphics.newImage "src/editor/layerselect.png")})

(fn Editor.set-layer [self layer]
  (set self.layer-index (util.clamp layer 1 (length self.map.layers))))

(fn Editor.set-layer-relative [self amount]
  (self:set-layer (+ self.layer-index amount)))

(set Editor.key-binds
     {
      :q (fn [self] (self:set-layer-relative -1))
      :a (fn [self] (self:set-layer-relative 1))})

(fn Editor.draw-map [self screen-size]
  (for [i (length self.map.layers) 1 -1]
    (when (= i self.layer-index)
      (love.graphics.translate -80 0)
      (love.graphics.setColor 1 0 0 0.2)
      (love.graphics.rectangle :fill 0 0 screen-size.x screen-size.y)
      (love.graphics.setColor 1 1 1)
      (love.graphics.translate 80 0))
    (self.map:draw-layer i)))

(fn Editor.draw [self {:screen-size screen-size}]
  ;; draw map
  (love.graphics.push)
  (love.graphics.translate 80 0)
  (self:draw-map screen-size)
  (love.graphics.pop)
  ;; draw UI
;;  (love.graphics.print self.layer-index)
  (love.graphics.draw self.layer-select-image 0 0))

(fn Editor.update [self])

(fn Editor.keypressed [self scancode]
  (when (. self.key-binds scancode) ((. self.key-binds scancode) self)))

(fn Editor.mousepressed [x y])

(Editor :test)
