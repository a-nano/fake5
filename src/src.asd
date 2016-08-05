(asdf:defsystem :src
  :class :package-inferred-system
  :defsystem-depends-on (:asdf-package-system)
  :pathname #p"./"
  :depends-on (:src/field :src/state :src/main :src/drawer :src/parser :src/types)
  :in-order-to ((test-op (load-op :src/test/field
                                  :src/test/state)))
  :perform (test-op (o c)
                    (lisp-unit:run-tests :all :src/test/field)
                    (lisp-unit:run-tests :all :src/test/state)))

(register-system-packages :spatial-trees '(:rectangles))
