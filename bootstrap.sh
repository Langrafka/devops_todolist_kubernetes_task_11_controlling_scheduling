#!/usr/bin/env bash
# bootstrap.sh: Скрипт розгортання та налаштування кластера
set -euo pipefail

# 1. Створення кластера
echo "--- 1. Створення кластера KIND ---"
kind delete cluster || true
kind create cluster --config cluster.yml

# Очікування готовності нод
echo "--- Очікування готовності нод ---"
kubectl wait --for=condition=Ready nodes --all --timeout=180s

# 2. Налаштування Нод (Labels & Taints)
echo "--- 2. Налаштування Node Labels та Taints ---"

# 2 ноди для MySQL
kubectl label nodes kind-worker app=mysql --overwrite
kubectl label nodes kind-worker2 app=mysql --overwrite

# 2 ноди для ToDo App
kubectl label nodes kind-worker3 app=todoapp --overwrite
kubectl label nodes kind-worker4 app=todoapp --overwrite

# 4. Taint nodes labeled with app=mysql with app=mysql:NoSchedule
kubectl taint nodes -l app=mysql app=mysql:NoSchedule --overwrite

# 3. Розгортання MySQL (StatefulSet) - ВИПРАВЛЕНО ШЛЯХ
echo "--- 3. Розгортання MySQL (StatefulSet) ---"
kubectl apply -f .infrastructure/mysql/statefulSet.yml
kubectl -n mysql rollout status sts/mysql --timeout=240s

# 4. Розгортання ToDo App (Deployment) - ВИПРАВЛЕНО ШЛЯХ
echo "--- 4. Розгортання ToDo App (Deployment) ---"
kubectl apply -f .infrastructure/app/deployment.yml
kubectl -n todo rollout status deploy/todo-app --timeout=240s

# 5. Фінальна Валідація
echo ""
echo "========================================================"
echo "    Фінальна Валідація: Перевірка Правил Планування     "
echo "========================================================"

# Валідація нод (Taints/Labels)
echo "[Nodes labels/taints - Вимога 3 та 4]"
kubectl get nodes --show-labels | grep worker
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" taints="}{.spec.taints}{"\n"}{end}' | grep worker

# Валідація MySQL (Affinity/Toleration) - Вимога 5
echo "--------------------------------------------------------"
kubectl -n mysql get po -l app=mysql -o wide
kubectl -n mysql get pod -l app=mysql -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName

# Валідація ToDo App (Preferred Affinity/Anti-Affinity) - Вимога 6
echo "--------------------------------------------------------"
kubectl -n todo get po -l app=todoapp -o wide
kubectl -n todo get pod -l app=todoapp -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName