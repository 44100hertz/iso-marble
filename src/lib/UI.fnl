(local Cache (require :src.lib.Cache))
(local UI (util.class))

(fn UI.constructor [tree]
  {:image-cache (Cache :image)
   :root tree})

(fn UI.mousepressed [self ...]
  (self:propagate-mouse-event self.root (Vec2 0 0) [:mousepressed ...]))

;; traverses the tree children-first, testing if the mouse is in their regions
(fn UI.propagate-mouse-event [self elem offset event]
  (let [(type props children) (unpack elem)
        {: position : size : display} props
        pos (+ position offset)
        (_ x y button) (unpack event)
        mouse-pos (- (Vec2 x y) offset)]
    (var child-has-mouse false)
    (when children (each [_i child (ipairs children) &until child-has-mouse]
                     (set child-has-mouse
                          (UI:propagate-mouse-event child pos event))))
    (if (and (not child-has-mouse)
             props.onclick
             (mouse-pos:within-rectangle pos size))
        (do
          (props:onclick x y button)
          true)
        child-has-mouse)))

(fn UI.draw [self]
  (self:draw-element self.root (Vec2 0 0)))

;; traverses the tree parents-first, drawing everything
(fn UI.draw-element [self elem offset]
  (let [(type props children) (unpack elem)
        {: position : size : display} props
        pos (+ position offset)
        display-type (if display (. display 1) :none)]
    (case display-type
      :image (let [image (self.image-cache:load (. display 2))
                   image-size (Vec2 (image:getDimensions))
                   scale (/ size image-size)]
               (love.graphics.draw image pos.x pos.y 0 scale.x scale.y))
      :none (do)
      _ (error (.. "Unknown display-type on " type ": " display-type)))
    (when children (each [_i child (ipairs children)]
                     (UI:draw-element child pos)))))

UI
