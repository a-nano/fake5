(defpackage :src/drawer
  (:nicknames :drawer)
  (:use :common-lisp :src/field :src/utils :cl-svg :cl-geometry)
  ;;(:import-from :mcts)
  (:import-from :spatial-trees)
  (:import-from :rectangles)
  (:import-from :src/types)
  (:import-from :src/parser)
  (:export #:draw-problem
           #:draw-polygons-to-svg
           #:dump-problems
           #:draw-action
           #:draw-classified-polygon))

(in-package :src/drawer)

(defparameter *scale* 500)
(defparameter *border* (round (/ *scale* 100)))
(defparameter *steps* 5)
(defparameter *x-shift* 0)
(defparameter *y-shift* 0)

(defun get-x (x)
  (round (+ *border* (* (+ *x-shift* x) *scale*))))

(defun get-y (y)
  (round (- *scale* (- (* (+ *y-shift* y) *scale*) *border*))))

(defun draw-field (scene)
  (let ((a1 *border*)
        (a2 (+ *border* *scale*))
        (a3 3)
        (step (round (/ *scale* *steps*)))
        (group
         (make-group scene (:stroke "black"
                                    ;;:fill color :opacity alpha
                                    :stroke-width 1
                                    ;;:fill-opacity (* alpha 0.6)
                                    ;;:stroke-linecap "round"
                                    )))
        (group2
         (make-group scene (:stroke "gray"
                                    ;;:fill color :opacity alpha
                                    :stroke-width 1
                                    ;;:fill-opacity (* alpha 0.6)
                                    ;;:stroke-linecap "round"
                                    :stroke-dasharray "5,5"))))
    (draw group (:line :x1 a1 :y1 a1 :x2 a2 :y2 a1))
    (draw group (:line :x1 a1 :y1 a1 :x2 a1 :y2 a2))
    (draw group (:line :x1 a2 :y1 a2 :x2 a1 :y2 a2))
    (draw group (:line :x1 a2 :y1 a2 :x2 a2 :y2 a1))
    (loop for i from 1 to (1- *steps*)
       do (let ((cur-a (+ *border* (* i step))))
            (draw group2 (:line :x1 cur-a :y1 *border* :x2 cur-a :y2 (+ *scale* *border*)))
            (draw group2 (:line :x1 *border* :y1 cur-a :x2 (+ *scale* *border*) :y2 cur-a))
            (draw group (:line :x1 cur-a :y1 (- *border* a3) :x2 cur-a :y2 (+ *border* a3)))
            (draw group (:line :x1 (- *border* a3) :y1 cur-a :x2 (+ *border* a3) :y2 cur-a))
            (draw group (:line :x1 cur-a :y1 (+ *scale* (- *border* a3)) :x2 cur-a :y2 (+ *scale* (+ *border* a3))))
            (draw group (:line :x1 (+ *scale* (- *border* a3)) :y1 cur-a :x2 (+ *scale* (+ *border* a3)) :y2 cur-a))
            ))))

(defmacro with-calculated-size ((polygons) &body body)
  `(let* ((bounding-box (or (reduce #'bounding-box-union (mapcar #'cl-geometry::construct-bounding-box ,polygons))
                            (make-instance 'cl-geometry::bounding-box
                                           :x-min 0
                                           :y-min 0
                                           :x-max 1
                                           :y-max 1)))
          (x-min (cl-geometry::x-min bounding-box))
          (x-max (cl-geometry::x-max bounding-box))
          (y-min (cl-geometry::y-min bounding-box))
          (y-max (cl-geometry::y-max bounding-box))
          (*x-shift* (if (or (> x-max 1) (< x-min 0))
                         (/ (- 1 (+ x-min x-max)) 2)
                         0))
          (*y-shift* (if (or (> y-max 1) (< y-min 0))
                         (/ (- 1 (+ y-min y-max)) 2)
                         0))
          (max-size (max (- x-max x-min) (- y-max y-min)))
          (*border* (if (> max-size 1)
                        (+ *border* (round (/ (* *scale* (- max-size 1)) 2)))
                        *border*))
          (size (+ *scale* (* 2 *border*))))
     ,@body))

(defun draw-text (scene text point)
  (text scene (:x (get-x (x point)) :y (get-y (y point))) text))

(defun draw-point (scene point)
  (draw scene (:circle :cx (get-x (x point)) :cy (get-y (y point)) :r 2)))

(defun draw-polygon (scene polygon &key stroke)
  (let* ((points (point-list polygon))
         (string-points (format nil "~{~A~^ ~}" (mapcar (lambda (point)
                                                          (format nil "~A,~A"
                                                                  (get-x (x point))
                                                                  (get-y (y point))))
                                                        points))))
    (if stroke
        (draw scene (:polygon :points string-points :fill "bisque" :stroke stroke))
        (draw scene (:polygon :points string-points :fill "bisque")))))

(defun draw-polygons-to-svg (polygons &key (filename "~/polygon.svg"))
  (draw-problem (polygons->problem polygons) :filename filename)
  ;; (with-calculated-size (polygons)
  ;;   (with-svg-to-file
  ;;       (scene 'svg-1.1-toplevel :height size :width size)
  ;;       (filename :if-exists :supersede)
  ;;     (mapc (lambda (polygon) (draw-polygon scene polygon :stroke "white")) polygons)
  ;;     (draw-field scene)))
  )

(defun draw-classified-polygon (polygon classification filename)
  (let* ((edges (edge-list polygon)))
    (with-calculated-size ((list polygon))
      (with-svg-to-file
          (scene 'svg-1.1-toplevel :height size :width size)
          (filename :if-exists :supersede)
        (draw-polygon scene polygon)
        (mapc (lambda (edge)
                (draw-line-segment
                 scene edge
                 :stroke (ecase (gethash edge classification)
                           (:entry "red")
                           (:exit "blue"))
                 :stroke-width 4))
              edges)
        (draw-field scene)))))

(defun draw-line-segment (scene line-segment &key (stroke "chocolate")
                                               (stroke-width 1))
  (let ((group
         (make-group scene (:stroke stroke
                                    ;;:fill color :opacity alpha
                                    :stroke-width stroke-width
                                    ;;:fill-opacity (* alpha 0.6)
                                    ;;:stroke-linecap "round"
                                    ))))
    (draw group (:line :x1 (get-x (x (start line-segment)))
                       :y1 (get-y (y (start line-segment)))
                       :x2 (get-x (x (end line-segment)))
                       :y2 (get-y (y (end line-segment)))))
    (draw group (:circle :cx (get-x (x (start line-segment))) :cy (get-y (y (start line-segment))) :r 2))
    (draw group (:circle :cx (get-x (x (end line-segment))) :cy (get-y (y (end line-segment))) :r 2))))

(defun bounding-box-union (box1 box2)
  (make-instance 'cl-geometry::bounding-box
                 :x-min (min (cl-geometry::x-min box1)
                             (cl-geometry::x-min box2))
                 :x-max (max (cl-geometry::x-max box1)
                             (cl-geometry::x-max box2))
                 :y-min (min (cl-geometry::y-min box1)
                             (cl-geometry::y-min box2))
                 :y-max (max (cl-geometry::y-max box1)
                             (cl-geometry::y-max box2))))

(defun draw-problem (problem &key (filename "~/field.svg"))
  (let* ((polygons (src/types:silhouette problem))
         (lines (src/types:skeleton problem)))
    (with-calculated-size (polygons)
      (with-svg-to-file
          (scene 'svg-1.1-toplevel :height size :width size)
          (filename :if-exists :supersede)
        (mapc (lambda (polygon) (draw-polygon scene polygon)) polygons)
        (mapc (lambda (line) (draw-line-segment scene line)) lines)
        (draw-field scene)))))

(defun draw-action (line point field polys filename)
  (with-calculated-size (field)
    (with-svg-to-file
        (scene 'svg-1.1-toplevel :height size :width size)
        (filename :if-exists :supersede)
      (mapc (lambda (polygon) (draw-polygon scene polygon)) polys)
      (if (= 0 (A line))
          (draw-line-segment scene
                             (make-instance 'line-segment
                                            :start (make-instance 'point
                                                                  :x 0
                                                                  :y (line-y-at-x line 0))
                                            :end (make-instance 'point
                                                                :x 1
                                                                :y (line-y-at-x line 1))))
          (draw-line-segment scene
                             (make-instance 'line-segment
                                            :start (make-instance 'point
                                                                  :y 0
                                                                  :x (line-x-at-y line 0))
                                            :end (make-instance 'point
                                                                :y 1
                                                                :x (line-x-at-y line 1)))))
      (draw-point scene point)
      (draw-field scene))))

(defun dump-problems (problem-folder &key (update-fn #'identity))
  (mapcar (lambda (problem-file)
            (handler-case
                (let ((problem (src/parser:parse-problem problem-file))
                      (svg-filename (format nil "~A.svg" problem-file)))
                  (draw-problem (funcall update-fn problem) :filename svg-filename)
                  t)
              (error (e) (format t "~A:~A~%" problem-file e))))
        (directory problem-folder)))

(defun update-non-solved-folder (root-folder)
  (let* ((svg-orig-folder-items (directory (format nil "~Asvg/orig/*.svg" root-folder)))
         (non-solved-folder (format nil "~Asvg/non-solved/" root-folder))
         (non-solved-svgs (directory (format nil "~A*.svg" non-solved-folder)))
         (solved-problems-dir (format nil "~Asolved-problems/" root-folder))
         (our-problems-dir (format nil "~Aour-problems/" root-folder)))
    (format t "~A" (format nil "~A*" non-solved-folder))
    (mapc (lambda (file)
            (delete-file file))
          non-solved-svgs)
    (mapc (lambda (file)
            (let ((name (pathname-name file)))
              (unless (or (probe-file (format nil "~A~A.txt" solved-problems-dir name))
                          (probe-file (format nil "~A~A.txt" our-problems-dir name)))
                (cl-fad:copy-file file (format nil "~A~A.svg" non-solved-folder name)))))
          svg-orig-folder-items)))
