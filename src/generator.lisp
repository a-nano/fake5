(defpackage :src/generator
  (:use :common-lisp
        :cl-geometry
        :src/drawer
	:src/simple-state
    :src/printer
    :src/matrix))

(in-package :src/generator)

(defun generator-test (file &key res-file)
  (let* ((new-specs)
         (specs-size 11)
         (m-for-rotation (1+ (random 10000)))
         (n-for-rotation (1+ (random 10000))))
    (loop for n from 1 to specs-size do
         (push (list :a (+ (random 3) 1/100) :b (+ (random 5) 1/100) :c (- (/ (random 7) (1+ (random 11)))) :x (random 7) :y (random 5)) new-specs))
    (labels ((%do ()
               (print-solution
                (mapcar (lambda (p) (rotate-polygon p m-for-rotation n-for-rotation))
                        (src/simple-state::fold-quad-and-show file new-specs :animate t)))))
      (if res-file
          (with-open-file (*standard-output* res-file :direction :output
                                             :if-exists :supersede
                                             :if-does-not-exist :create)
            (%do))
          (%do)))))

(defun generate-many (n folder)
  (loop for x from 1 to n do
       (src/generator::generator-test (format nil "~A/~A.svg" folder x)
				      :res-file (format nil "~A/~A.txt" folder x))))
