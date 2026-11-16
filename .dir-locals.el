((odin-mode
  . ((eval . (let ((dir (shell-quote-argument
                         (file-name-directory buffer-file-name))))
                (setq-local +odin-build-command
                            (format "cd %s && odin build . -debug" dir)
                            +odin-test-command
                            (format "cd %s && odin test ." dir)
                            +odin-run-command
                            (format "cd %s && odin run ." dir))))))
 (odin-ts-mode
  . ((eval . (let ((dir (shell-quote-argument
                         (file-name-directory buffer-file-name))))
                (setq-local +odin-build-command
                            (format "cd %s && odin build . -debug" dir)
                            +odin-test-command
                            (format "cd %s && odin test ." dir)
                            +odin-run-command
                            (format "cd %s && odin run ." dir)))))))
