(var Editor (util.class))

(local LevelMap (require "src/LevelMap"))

(fn Editor.constructor [levelname]
  {:map (LevelMap levelname)
   :layer-index 1})

(fn Editor.draw-map [self screen-size]
  (for [i (length self.map.map.layers) 1 -1]
    (when (= i self.layer-index)
      (love.graphics.translate -80 0)
      (love.graphics.setColor 1 0 0 0.2)
      (love.graphics.rectangle :fill 0 0 screen-size.x screen-size.y)
      (love.graphics.setColor 1 1 1)
      (love.graphics.translate 80 0))
    (self.map:draw-layer i)))

(fn Editor.draw [self {:screen-size screen-size}]
  (love.graphics.clear 0 0 0)
  (love.graphics.translate 80 0)
  (self:draw-map screen-size))
(fn Editor.update [self])
(fn Editor.keypressed [self])

(Editor :test)
