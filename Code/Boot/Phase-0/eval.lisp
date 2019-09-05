(cl:in-package #:sicl-boot-phase-0)

(defmethod cleavir-cst-to-ast:cst-eval ((client client) cst environment)
  (sicl-hir-interpreter:cst-eval client cst environment))

(defmethod cleavir-cst-to-ast:eval ((client client) form environment)
  (let ((cst (cst:cst-from-expression form)))
    (sicl-hir-interpreter:cst-eval client cst environment)))
