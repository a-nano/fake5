(defpackage :src/drawer
  (:nicknames :drawer)
  (:use :common-lisp :src/field :src/utils :cl-svg)
  ;;(:import-from :mcts)
  (:import-from :spatial-trees)
  (:import-from :rectangles))

(in-package :src/drawer)

(defparameter *scale* 500)
(defparameter *border* (round (/ *scale* 100)))
(defparameter *steps* 5)

(defun draw-field (scene)
  (let ((a1 *border*)
        (a2 (+ *border* *scale*))
        (a3 (round (/ *border* 2)))
        (step (round (/ *scale* *steps*)))
        (group
         (make-group scene (:stroke "black"
                                    ;;:fill color :opacity alpha
                                    :stroke-width 1
                                    ;;:fill-opacity (* alpha 0.6)
                                    ;;:stroke-linecap "round"
                                    ))))
    (draw group (:line :x1 a1 :y1 a1 :x2 a2 :y2 a1))
    (draw group (:line :x1 a1 :y1 a1 :x2 a1 :y2 a2))
    (draw group (:line :x1 a2 :y1 a2 :x2 a1 :y2 a2))
    (draw group (:line :x1 a2 :y1 a2 :x2 a2 :y2 a1))
    (loop for i from 1 to (1- *steps*)
       do (let ((cur-a (* i step)))
            (draw group (:line :x1 cur-a :y1 (- *border* a3) :x2 cur-a :y2 (+ *border* a3)))
            (draw group (:line :x1 (- *border* a3) :y1 cur-a :x2 (+ *border* a3) :y2 cur-a))
            (draw group (:line :x1 cur-a :y1 (+ *scale* (- *border* a3)) :x2 cur-a :y2 (+ *scale* (+ *border* a3))))
            (draw group (:line :x1 (+ *scale* (- *border* a3)) :y1 cur-a :x2 (+ *scale* (+ *border* a3)) :y2 cur-a))
            ))))

(defun draw-state (field &key (filename #p"~/field.svg"))
  (declare (ignore field))
  (let ((size (+ *scale* (* 2 *border*))))
    (with-svg-to-file
        (scene 'svg-1.1-toplevel :height size :width size)
        (filename :if-exists :supersede)
      (draw-field scene))))
