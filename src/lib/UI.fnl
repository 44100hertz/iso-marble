(local Cache (require :src.lib.Cache))
(local UI (util.class))

(fn UI.constructor [tree]
  {:image-cache (Cache :image)
   :root tree})

(fn UI.mousepressed [self x y button])

(fn UI.draw [self]
  (self:draw-element self.root))

(fn UI.draw-element [self elem offset]
  (let [offset (or offset (Vec2 0 0))
        (type props children) (unpack elem)
        {: position : size : display} props
        pos (+ position offset)
        display-type (. display 1)]
    (case display-type
      :image (let [image (self.image-cache:load (. display 2))
                   image-size (Vec2 (image:getDimensions))
                   scale (/ size image-size)]
               (love.graphics.draw image pos.x pos.y 0 scale.x scale.y))
      _ (error (.. "Unknown display-type on " type ": " display-type)))

    (when children (each [_i child (ipairs children)]
                     (UI:draw-element child pos)))))

UI
