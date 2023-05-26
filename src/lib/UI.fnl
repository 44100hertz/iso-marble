(local Cache (require :src.lib.Cache))
(local UI (util.class))

(fn UI.constructor [tree]
  {:image-cache (Cache :image)
   :quad-cache (Cache :quad)
   :root tree})

(fn UI.instantiate [self tree]
  (self:update-element self.root))

(fn UI.mousepressed [self ...]
  (self:propagate-mouse-event self.root (Vec2 0 0) [:mousepressed ...]))

;; Call 'update' on an element, which should set its contents to the correct
;; stuff.
(fn UI.update-element [self elem]
  (let [(type props children) (unpack elem)]
    (when props.update (props.update elem))
    (when props.watch
      (let [[table index] props.watch]
        (set props.watch-prev (. table index))))
    (when children (each [_i child (ipairs children)]
                     (self:update-element child)))))

;; return true if a watched value is different than it was before
(fn UI.check-watch [self props]
  (when props.watch
      (let [[table index] props.watch]
        (not= (. table index) props.watch-prev))))

;; traverses the tree children-first, testing if the mouse is in their regions
(fn UI.propagate-mouse-event [self elem offset event]
  (let [[type props children] elem
        {: position : size : display} props
        pos (+ position offset)
        (_ x y button) (unpack event)
        mouse-pos (Vec2 x y)]
    (when (not props.disabled)
      (var child-has-mouse false)
      (when children (each [_i child (ipairs children) &until child-has-mouse]
                       (set child-has-mouse
                            (UI:propagate-mouse-event child pos event))))
      (if (and (not child-has-mouse)
               props.onclick
               (mouse-pos:within-rectangle pos size))
          (do
            (props.onclick elem x y button)
            true)
          child-has-mouse))))

(fn UI.draw [self]
  (self:draw-element self.root (Vec2 0 0)))

;; traverses the tree parents-first, drawing everything
(fn UI.draw-element [self elem offset]
  (let [[type props children] elem
        {: position : size : display} props
        pos (+ position offset)
        display-type (if display (. display 1) :none)]
    (if (self:check-watch props) (self:update-element elem))
    (when (not props.disabled)
      (case display-type
        :image (let [(_ image-path) (unpack display)
                     image (self.image-cache:load image-path)
                     image-size (Vec2 (image:getDimensions))
                     scale (/ size image-size)
                     color (or props.color [1 1 1 1])]
                 (love.graphics.setColor color)
                 (love.graphics.draw image pos.x pos.y 0 scale.x scale.y))
        :image-quad (let [(_ image-path x y w h) (unpack display)
                          image (self.image-cache:load image-path)
                          quad (self.quad-cache:load image x y w h)
                          scale (/ size (Vec2 w h))
                          color (or props.color [1 1 1 1])]
                      (love.graphics.setColor color)
                      (love.graphics.draw image quad pos.x pos.y 0 scale.x scale.y))
        :none (do)
        _ (error (.. "Unknown display-type on " type ": " display-type)))
      (if (?. _G.DEBUG :ui-position)
          (util.with-color-rgba 1 0 0 1
            #(love.graphics.rectangle :line pos.x pos.y size.x size.y)))
      (when children (each [_i child (ipairs children)]
                       (self:draw-element child pos))))))

UI
