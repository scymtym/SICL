(cl:in-package #:sicl-new-boot-phase-2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Creating class accessor generic functions.

(defun ensure-generic-function-phase-2 (boot)
  (let* ((class-env (sicl-new-boot:e1 boot))
         (gf-class-name 'standard-generic-function)
         (gf-class (sicl-genv:find-class gf-class-name class-env))
         (method-class-name 'standard-method)
         (method-class (sicl-genv:find-class method-class-name class-env))
         (target-env (sicl-new-boot:e3 boot)))
    (setf (sicl-genv:fdefinition 'ensure-generic-function target-env)
          (lambda (function-name &rest arguments
                   &key environment
                   &allow-other-keys)
            (let ((args (copy-list arguments)))
              (loop while (remf args :environment))
              (if (sicl-genv:fboundp function-name environment)
                  (sicl-genv:fdefinition function-name environment)
                  (setf (sicl-genv:fdefinition function-name environment)
                        (apply #'make-instance gf-class
                               :name function-name
                               :method-class method-class
                               args))))))))

;;; FIXME: remove the :AROUND method after booting is complete.
(defun set-up-generic-function-initialization (boot)
  (let* ((temp (gensym))
         (class-env (sicl-new-boot:e1 boot))
         (gf-class-name 'generic-function)
         (gf-class (sicl-genv:find-class gf-class-name class-env)))
    (setf (find-class temp) gf-class)
    (eval `(defmethod shared-initialize :around
            ((generic-function ,temp)
             slot-names
             &rest initargs
             &key &allow-other-keys)
            (apply #'sicl-clos::shared-initialize-around-generic-function-default
             #'call-next-method
             #'identity
             generic-function
             slot-names
             initargs)))
    (setf (find-class temp) gf-class) nil))

(defun load-accessor-defgenerics (boot)
  (sicl-minimal-extrinsic-environment:host-load
   "CLOS/generic-function-initialization-support.lisp")
  (let ((e (sicl-new-boot:e3 boot)))
    (sicl-minimal-extrinsic-environment:import-function-from-host
     'sicl-clos:defgeneric-expander e)
    (load-file "CLOS/defgeneric-defmacro.lisp" e)
    (ensure-generic-function-phase-2 boot)
    (set-up-generic-function-initialization boot)
    (load-file "CLOS/specializer-direct-generic-functions-defgeneric.lisp" e)
    (load-file "CLOS/setf-specializer-direct-generic-functions-defgeneric.lisp" e)
    (load-file "CLOS/specializer-direct-methods-defgeneric.lisp" e)
    (load-file "CLOS/setf-specializer-direct-methods-defgeneric.lisp" e)
    (load-file "CLOS/eql-specializer-object-defgeneric.lisp" e)
    (load-file "CLOS/unique-number-defgeneric.lisp" e)
    (load-file "CLOS/class-name-defgeneric.lisp" e)
    (load-file "CLOS/class-direct-subclasses-defgeneric.lisp" e)
    (load-file "CLOS/setf-class-direct-subclasses-defgeneric.lisp" e)
    (load-file "CLOS/class-direct-default-initargs-defgeneric.lisp" e)
    (load-file "CLOS/documentation-defgeneric.lisp" e)
    (load-file "CLOS/setf-documentation-defgeneric.lisp" e)
    (load-file "CLOS/class-finalized-p-defgeneric.lisp" e)
    (load-file "CLOS/setf-class-finalized-p-defgeneric.lisp" e)
    (load-file "CLOS/class-precedence-list-defgeneric.lisp" e)
    (load-file "CLOS/precedence-list-defgeneric.lisp" e)
    (load-file "CLOS/setf-precedence-list-defgeneric.lisp" e)
    (load-file "CLOS/instance-size-defgeneric.lisp" e)
    (load-file "CLOS/setf-instance-size-defgeneric.lisp" e)
    (load-file "CLOS/class-direct-slots-defgeneric.lisp" e)
    (load-file "CLOS/class-direct-superclasses-defgeneric.lisp" e)
    (load-file "CLOS/class-default-initargs-defgeneric.lisp" e)
    (load-file "CLOS/setf-class-default-initargs-defgeneric.lisp" e)
    (load-file "CLOS/class-slots-defgeneric.lisp" e)
    (load-file "CLOS/setf-class-slots-defgeneric.lisp" e)
    (load-file "CLOS/class-prototype-defgeneric.lisp" e)
    (load-file "CLOS/setf-class-prototype-defgeneric.lisp" e)
    (load-file "CLOS/dependents-defgeneric.lisp" e)
    (load-file "CLOS/setf-dependents-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-name-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-lambda-list-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-argument-precedence-order-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-declarations-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-method-class-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-method-combination-defgeneric.lisp" e)
    (load-file "CLOS/generic-function-methods-defgeneric.lisp" e)
    (load-file "CLOS/setf-generic-function-methods-defgeneric.lisp" e)
    (load-file "CLOS/initial-methods-defgeneric.lisp" e)
    (load-file "CLOS/setf-initial-methods-defgeneric.lisp" e)
    (load-file "CLOS/call-history-defgeneric.lisp" e)
    (load-file "CLOS/setf-call-history-defgeneric.lisp" e)
    (load-file "CLOS/specializer-profile-defgeneric.lisp" e)
    (load-file "CLOS/setf-specializer-profile-defgeneric.lisp" e)
    (load-file "CLOS/method-function-defgeneric.lisp" e)
    (load-file "CLOS/method-generic-function-defgeneric.lisp" e)
    (load-file "CLOS/setf-method-generic-function-defgeneric.lisp" e)
    (load-file "CLOS/method-lambda-list-defgeneric.lisp" e)
    (load-file "CLOS/method-specializers-defgeneric.lisp" e)
    (load-file "CLOS/method-qualifiers-defgeneric.lisp" e)
    (load-file "CLOS/accessor-method-slot-definition-defgeneric.lisp" e)
    (load-file "CLOS/setf-accessor-method-slot-definition-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-name-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-allocation-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-type-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-initargs-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-initform-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-initfunction-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-storage-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-readers-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-writers-defgeneric.lisp" e)
    (load-file "CLOS/slot-definition-location-defgeneric.lisp" e)
    (load-file "CLOS/setf-slot-definition-location-defgeneric.lisp" e)
    (load-file "CLOS/operation-defgeneric.lisp" e)))