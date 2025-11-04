# INSTRUCTION.md: Детальна інструкція з валідації (Вимога 8)

Цей документ містить покрокові інструкції для перевірки виконання вимог планування (Taints, Tolerations, Affinity, Anti-Affinity) після запуску `./bootstrap.sh`.

## Крок 1: Запуск Кластера та Розгортання

Виконайте наступну команду у кореневому каталозі проєкту, щоб створити кластер, налаштувати ноди та розгорнути додатки:

```bash
chmod +x bootstrap.sh
./bootstrap.sh

## Крок 2: Валідація Нод (Taints та Labels)
Перевірте, чи коректно застосовано лейбли та Taint згідно з Вимогами 3 та 4.

Команди:
Bash

kubectl get nodes --show-labels
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" taints="}{.spec.taints}{"\n"}{end}'
Очікування:
MySQL ноди: kind-worker та kind-worker2 повинні мати Label: app=mysql та Taint: app=mysql:NoSchedule.

ToDo App ноди: kind-worker3 та kind-worker4 повинні мати Label: app=todoapp і НЕ мати Taint app=mysql:NoSchedule.

##  Крок 3: Валідація MySQL StatefulSet (Вимога 5)
Перевірте, чи поди MySQL розміщені тільки на "спеціалізованих" нодах і розсіяні.

Команди:
Bash

kubectl -n mysql get po -l app=mysql -o wide
kubectl -n mysql get pod -l app=mysql -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
Очікування:
Node Affinity (5.3) & Toleration (5.1): Поди mysql-0 та mysql-1 повинні бути розміщені на нодах kind-worker та kind-worker2 (ноди з Taint app=mysql:NoSchedule).

Pod Anti-Affinity (5.2): Кожен mysql-pod повинен бути розміщений на РІЗНИХ нодах.

##  Крок 4: Валідація ToDo App Deployment (Вимога 6)
Перевірте, чи поди Django App розсіяні та розміщені на "бажаних" нодах.

Команди:
Bash

kubectl -n todo get po -l app=todoapp -o wide
kubectl -n todo get pod -l app=todoapp -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
Очікування:
Pod Anti-Affinity (6.2): Репліки (todo-app-*) повинні бути розміщені на РІЗНИХ нодах.

Node Affinity (Preferred) (6.1): Репліки повинні бути розміщені на нодах з Label: app=todoapp (kind-worker3 та kind-worker4), оскільки це бажана, але не обов'язкова умова.