(cl:in-package #:sicl-new-boot-phase-2)

;;; We already know how to execute a DEFGENERIC form in E2.  Now we
;;; need to know how to use DEFMETHOD to define methods on the generic
;;; functions we create with DEFGENERIC.  That is the purpose of this
;;; function.

;;; When we need to find a class in E2, like for creating a method
;;; metaobject, or for finding a specializer for some method, we need
;;; to find a host class, and the host classes are present in E1, so
;;; we need a special version of SICL-GENV:FIND-CLASS in E2 that
;;; ignores its ENVIRONMENT parameter and looks up the class in E1
;;; instead.
(defun define-find-class-in-e2 (e1 e2)
  (setf (sicl-genv:fdefinition 'sicl-genv:find-class e2)
        (lambda (class-name environment)
          (declare (ignore environment))
          (sicl-genv:find-class class-name e1))))

;;; The problem that we are solving with this function is the
;;; following: In phase 1, we loaded a bunch of definitions of host
;;; generic functions into E2.  We also loaded definitions of host
;;; classes (corresponding to MOP classes) into E1.  When those
;;; classes were loaded, methods corresponding to class accessors were
;;; added to the generic functions in E2.  Among them,
;;; GENERIC-FUNCTION-METHOD-CLASS.  That method works when given an
;;; instance of the GENERIC-FUNCTION class defined in E1, but it
;;; doesn't work when given an instance of the host
;;; STANDARD-GENERIC-FUNCTION.  Now, in phase 2, we need to add
;;; methods to the generic functions in E2, and to create such a
;;; method, ENSURE-METHOD calls GENERIC-FUNCTION-METHOD-CLASS which
;;; won't work.
;;;
;;; We solve the problem by adding a method on
;;; GENERIC-FUNCTION-METHOD-CLASS in E2 that calls the host version of
;;; the function with that name.
(defun define-method-on-generic-function-method-class (e2)
  (let ((temp (gensym)))
    (setf (fdefinition temp)
          (sicl-genv:fdefinition 'sicl-clos:generic-function-method-class e2))
    (eval `(defmethod ,temp ((generic-function standard-generic-function))
             (closer-mop:generic-function-method-class generic-function)))
    (fmakunbound temp)))

;;; When we load the file containing ENSURE-METHOD, we also define the
;;; function MAKE-SPECIALIZER.  However that function does the wrong
;;; thing in case the specializer given is the symbol T, because then
;;; it looks up T in E1 and we get an automatic specialization on the
;;; host class FUNCALLABLE-STANDARD-OBJECT which is obviously not what
;;; we want.  So we define a special version of MAKE-SPECIALIZER here.
;;; It does not have to do any error checking, and it handles T
;;; specially by looking up the class T in the host environment
;;; instead of in E1.
(defun define-make-specializer (e1 e2)
  (setf (sicl-genv:fdefinition 'sicl-clos::make-specializer e2)
        (lambda (specializer)
          (cond ((eq specializer 't)
                 (find-class 't))
                ((symbolp specializer)
                 (sicl-genv:find-class specializer e1))
                (t
                 specializer)))))

(defun enable-defmethod-in-e2 (boot)
  (with-accessors ((e1 sicl-new-boot:e1)
                   (e2 sicl-new-boot:e2)) boot
    ;; FIND-CLASS is used by ENSURE-METHOD to look up a class as a
    ;; specializer when a symbol is given.
    (define-find-class-in-e2 e1 e2)
    ;; TYPEP is used by ENSURE-METHOD to check that, if a symbol was
    ;; not given, then an instance of SPECIALIZER was.
    (import-function-from-host 'sicl-genv:typep e2)
    ;; PROPER-LIST-P is used by ENSURE-METHOD to check that the list
    ;; of specializers given is a proper list.
    (import-function-from-host 'cleavir-code-utilities:proper-list-p e2)
    (define-method-on-generic-function-method-class e2)
    (import-function-from-host 'add-method e2)
    (import-function-from-host 'copy-list e2)
    (setf (sicl-genv:fdefinition 'sicl-clos:make-method-lambda e1)
          #'sicl-clos::make-method-lambda-default)
    (setf (sicl-genv:fdefinition 'ensure-generic-function e1)
          (sicl-genv:fdefinition 'ensure-generic-function e2))
    (import-functions-from-host
     '(mapcar
       subseq
       1+
       elt
       position-if
       sicl-genv:find-class
       sicl-genv:typep
       sicl-genv:fboundp
       sicl-genv:fdefinition
       cleavir-code-utilities:separate-function-body
       cleavir-code-utilities:required
       cleavir-code-utilities:parse-specialized-lambda-list)
     e1)
    (setf (sicl-genv:fdefinition 'sicl-clos:class-prototype e1)
          #'closer-mop:class-prototype)
    (setf (sicl-genv:fdefinition 'sicl-clos:generic-function-method-class e1)
          #'closer-mop:generic-function-method-class)
    (load-file "CLOS/defmethod-support.lisp" e1)
    (setf (sicl-genv:fdefinition 'sicl-clos:defmethod-expander e2)
          (sicl-genv:fdefinition 'sicl-clos:defmethod-expander e1))
    ;; ENSURE-METHOD calls MAKE-SPECIALIZER, but the version of
    ;; MAKE-SPECIALIZER that is in the file with that name is not
    ;; correct for phase 2.  Fix the problem by defining a special
    ;; version of it.
    (define-make-specializer e1 e2)
    (load-file "CLOS/make-method-for-generic-function.lisp" e2)
    (import-functions-from-host
     '(cleavir-code-utilities:proper-list-p
       add-method
       copy-list)
     e1)
    (load-file "CLOS/make-specializer.lisp" e1)
    (load-file "CLOS/ensure-method.lisp" e2)
    (load-file "CLOS/defmethod-defmacro.lisp" e2)))