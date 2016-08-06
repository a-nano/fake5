(defpackage :src/generator
  (:use :common-lisp
        :cl-geometry
        :src/drawer
	:src/simple-state
        :src/printer))

(in-package :src/generator)

(defun generator-test (file &key res-file)
  (let* ((new-specs)
	 (specs-size 11))
    (loop for n from 1 to specs-size do
	 (push (list :a (+ (random 5) 1/100) :b (+ (random 2) 1/100) :c (- (/ (random 2) (1+ (random 3)))) :x (random 2) :y (random 3)) new-specs))
    (labels ((%do ()
               (print-solution
                (src/simple-state::fold-quad-and-show file new-specs :animate t))))
      (if res-file
          (with-open-file (*standard-output* res-file :direction :output
                                             :if-exists :supersede
                                             :if-does-not-exist :create)
            (%do))
          (%do)))))
