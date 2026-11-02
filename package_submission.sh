#!/usr/bin/env bash
# ==============================================================================
# package_submission.sh
# Packaging Script for MIT 8103 Advanced Database Systems Continuous Assessment
# Miva Open University — School of Post Graduate Studies
# Student: Bamishaye Favour (ID: 301915930)
# ==============================================================================

set -euo pipefail

# 1. Configuration & Constants
SURNAME="Bamishaye"
FIRSTNAME="Favour"
STUDENT_ID="301915930"
TARGET_DIR="${SURNAME}_${FIRSTNAME}_${STUDENT_ID}"
ZIP_NAME="${TARGET_DIR}.zip"
README_TXT="${SURNAME}_${FIRSTNAME}_README.txt"

echo "======================================================================"
echo " Packaging Database Portfolio for ${FIRSTNAME} ${SURNAME} (${STUDENT_ID})"
echo "======================================================================"

# 2. Reset Target Directory
if [ -d "${TARGET_DIR}" ]; then
    echo "[*] Cleaning existing target directory: ${TARGET_DIR}..."
    rm -rf "${TARGET_DIR}"
fi
if [ -f "${ZIP_NAME}" ]; then
    echo "[*] Cleaning existing zip archive: ${ZIP_NAME}..."
    rm -f "${ZIP_NAME}"
fi

# 3. Create Clean Structure (NO SPACES anywhere in folder names)
mkdir -p "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/Screenshots"
mkdir -p "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Screenshots"
mkdir -p "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Output"
mkdir -p "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/Screenshots"
mkdir -p "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/Output"
mkdir -p "${TARGET_DIR}/Portfolio_4_NoSQL_Store/Screenshots"
mkdir -p "${TARGET_DIR}/Portfolio_4_NoSQL_Store/Output"
mkdir -p "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/Screenshots"
mkdir -p "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/Output"

echo "[+] Directory structure created."

# 4. Copy Root Synthesis Documents
cp "Bamishaye_Favour_README.txt" "${TARGET_DIR}/${README_TXT}"
cp "Bamishaye_Favour_Final_Report.md" "${TARGET_DIR}/${SURNAME}_${FIRSTNAME}_Final_Report.md"
if [ -f "Bamishaye_Favour_Final_Report.pdf" ]; then
    cp "Bamishaye_Favour_Final_Report.pdf" "${TARGET_DIR}/${SURNAME}_${FIRSTNAME}_Final_Report.pdf"
fi
cp "Bamishaye_Favour_AI_Use_Declaration.md" "${TARGET_DIR}/${SURNAME}_${FIRSTNAME}_AI_Use_Declaration.md"
cp "Bamishaye_Favour_References.md" "${TARGET_DIR}/${SURNAME}_${FIRSTNAME}_References.md"
echo "[+] Root synthesis documents copied."

# 5. Copy & Rename Portfolio 1: Design & Modelling
cp "portfolio-1-database-design/case-study.md" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_CaseStudy.md"
cp "portfolio-1-database-design/nexora.dbml" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_RelationalSchema.md"
cp "portfolio-1-database-design/nexora.dbml" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_ERD.dbml"
cp "portfolio-1-database-design/normalisation.md" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_Normalisation.md"
cp "portfolio-1-database-design/00_create_database.sql" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_CreateDatabase.sql"
cp "portfolio-1-database-design/01_verify_setup.sql" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_VerifySetup.sql"
cp "portfolio-1-database-design/02_create_tables.sql" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_CreateSchema.sql"
cp "portfolio-1-database-design/03_constraint_tests.sql" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_ConstraintTests.sql"
cp "portfolio-1-database-design/04_seed_data.sql" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_SeedData.sql"
cp "portfolio-1-database-design/05_verify_seed.sql" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_VerifySeed.sql"
cp "portfolio-1-database-design/README.md" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_P1_README.md"
cp "portfolio-1-database-design/screenshots/Bamishaye_Favour_301915930_er_diagram.png" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/${SURNAME}_${FIRSTNAME}_ERD.png"

# Copy P1 Screenshots
for img in portfolio-1-database-design/screenshots/*.png; do
    if [ -f "$img" ]; then
        cp "$img" "${TARGET_DIR}/Portfolio_1_Design_And_Modelling/Screenshots/"
    fi
done
echo "[+] Portfolio 1 files packaged."

# 6. Copy & Rename Portfolio 2: Query Optimisation
cp "portfolio-2-query-optimisation/README.md" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_README.md"
cp "portfolio-2-query-optimisation/performance-analysis.md" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_PerformanceResults.md"
cp "portfolio-2-query-optimisation/sql/01_capture_plans.sql" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_CapturePlans.sql"
cp "portfolio-2-query-optimisation/sql/02_query_results.sql" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_QueryResults.sql"
cp "portfolio-2-query-optimisation/sql/03_create_indexes.sql" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_CreateIndexes.sql"
cp "portfolio-2-query-optimisation/sql/04_drop_indexes.sql" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_DropIndexes.sql"
cp "portfolio-2-query-optimisation/sql/05_planner_experiments.sql" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_PlannerExperiments.sql"
cp "portfolio-2-query-optimisation/sql/06_write_cost.sql" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_WriteCost.sql"

# Copy individual queries and create consolidated queries file
cat portfolio-2-query-optimisation/queries/*.sql > "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_Queries.sql"
for q in portfolio-2-query-optimisation/queries/*.sql; do
    bname=$(basename "$q")
    cp "$q" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/${SURNAME}_${FIRSTNAME}_P2_${bname}"
done

# Copy plan logs
cp "portfolio-2-query-optimisation/plans/before.txt" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Output/${SURNAME}_${FIRSTNAME}_P2_Plans_Before.txt"
cp "portfolio-2-query-optimisation/plans/after.txt" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Output/${SURNAME}_${FIRSTNAME}_P2_Plans_After.txt"
cp "portfolio-2-query-optimisation/plans/results.txt" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Output/${SURNAME}_${FIRSTNAME}_P2_Plans_Results.txt"
cp "portfolio-2-query-optimisation/plans/planner.txt" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Output/${SURNAME}_${FIRSTNAME}_P2_Plans_Planner.txt"

# Copy P2 Screenshots
for img in portfolio-2-query-optimisation/screenshots/*.png; do
    if [ -f "$img" ]; then
        cp "$img" "${TARGET_DIR}/Portfolio_2_Query_Optimisation/Screenshots/"
    fi
done
echo "[+] Portfolio 2 files packaged."

# 7. Copy & Rename Portfolio 3: Transactions & Concurrency
cp "portfolio-3-transactions-concurrency/README.md" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_README.md"
cp "portfolio-3-transactions-concurrency/analysis.md" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_ConcurrencyAnalysis.md"
cp "portfolio-3-transactions-concurrency/own_experiment.md" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_LockTimeoutExperiment.md"
cp "portfolio-3-transactions-concurrency/sql/01_transfer_function.sql" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_TransactionScripts.sql"
cp "portfolio-3-transactions-concurrency/sql/02_demo_setup.sql" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_DemoSetup.sql"
cp "portfolio-3-transactions-concurrency/sql/03_commit_rollback_demo.sql" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_CommitRollbackDemo.sql"
cp "portfolio-3-transactions-concurrency/sql/04_stress_ordered.pgbench" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_StressTest_Ordered.pgbench"
cp "portfolio-3-transactions-concurrency/sql/05_stress_unordered.pgbench" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_StressTest_Unordered.pgbench"
cp "portfolio-3-transactions-concurrency/sql/06_integrity_check.sql" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_IntegrityCheck.sql"

# Create helper runner script for stress testing
cat << 'EOF' > "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_StressTest.sh"
#!/usr/bin/env bash
# Runner for Portfolio 3 Concurrency Stress Testing
DB="${1:-nexora_db}"
echo "[*] Running Ordered Locking Stress Test on $DB..."
pgbench -d "$DB" -c 10 -j 2 -t 200 -f Bamishaye_Favour_P3_StressTest_Ordered.pgbench
echo "[*] Running Naive Unordered Locking Stress Test on $DB..."
pgbench -d "$DB" -c 10 -j 2 -t 200 -f Bamishaye_Favour_P3_StressTest_Unordered.pgbench
EOF
chmod +x "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/${SURNAME}_${FIRSTNAME}_P3_StressTest.sh"

# Copy outputs
for out in portfolio-3-transactions-concurrency/output/*.txt; do
    bname=$(basename "$out")
    cp "$out" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/Output/${SURNAME}_${FIRSTNAME}_P3_${bname}"
done

# Copy P3 Screenshots
for img in portfolio-3-transactions-concurrency/screenshots/*.png; do
    if [ -f "$img" ]; then
        cp "$img" "${TARGET_DIR}/Portfolio_3_Transactions_And_Concurrency/Screenshots/"
    fi
done
echo "[+] Portfolio 3 files packaged."

# 8. Copy & Rename Portfolio 4: NoSQL Document Store
cp "portfolio-4-nosql/README.md" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_README.md"
cp "portfolio-4-nosql/nosql-model-design.md" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_NoSQLModelDesign.md"
cp "portfolio-4-nosql/sql-vs-nosql-rational.md" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_SQLvsNoSQLRationale.md"
cp "portfolio-4-nosql/script/01_schema_validation.js" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_SchemaValidation.js"
cp "portfolio-4-nosql/script/02_seed_data.js" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_SeedData.js"
cp "portfolio-4-nosql/script/03_crud_and_aggregation.js" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_CrudAndAggregation.js"
cp "portfolio-4-nosql/script/04_indexes_explain.js" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_IndexesExplain.js"

# Consolidated scripts file
cat portfolio-4-nosql/script/*.js > "${TARGET_DIR}/Portfolio_4_NoSQL_Store/${SURNAME}_${FIRSTNAME}_P4_Scripts.js"

# Copy outputs
for out in portfolio-4-nosql/output/*.txt; do
    bname=$(basename "$out")
    cp "$out" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/Output/${SURNAME}_${FIRSTNAME}_P4_${bname}"
done

# Copy P4 Screenshots
for img in portfolio-4-nosql/screenshots/*.png; do
    if [ -f "$img" ]; then
        cp "$img" "${TARGET_DIR}/Portfolio_4_NoSQL_Store/Screenshots/"
    fi
done
echo "[+] Portfolio 4 files packaged."

# 9. Copy & Rename Portfolio 5: Distributed & Cloud
cp "portfolio-5-distributed-cloud/README.md" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_README.md"
cp "portfolio-5-distributed-cloud/analysis.md" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_ReplicationAndFailover.md"
cp "portfolio-5-distributed-cloud/01_primary_checks.sql" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_PrimaryChecks.sql"
cp "portfolio-5-distributed-cloud/02_replica_checks.sql" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_ReplicaChecks.sql"
cp "portfolio-5-distributed-cloud/03_partitioning.sql" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_ShardingPartitioning.sql"
cp "portfolio-5-distributed-cloud/04_atlas_cloud_check.js" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_AtlasCloudCheck.js"
cp "portfolio-5-distributed-cloud/docker-compose.yml" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_DockerCompose.yml"
cp "portfolio-5-distributed-cloud/replica-entrypoint.sh" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_ReplicaEntrypoint.sh"
cp "portfolio-5-distributed-cloud/primary-init/01_replication.sh" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_PrimaryInit.sh"

# Runner script for Portfolio 5 cluster orchestration
cat << 'EOF' > "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_Scripts.sh"
#!/usr/bin/env bash
# Runner for Portfolio 5 Distributed Topology Verification
echo "[*] Launching PostgreSQL Primary and Standby containers..."
docker compose -f Bamishaye_Favour_P5_DockerCompose.yml up -d
echo "[*] Checking Primary replication status..."
sleep 3
psql -h localhost -p 5433 -U postgres -d nexora_db -f Bamishaye_Favour_P5_PrimaryChecks.sql
echo "[*] Checking Hot Standby recovery status..."
psql -h localhost -p 5434 -U postgres -d nexora_db -f Bamishaye_Favour_P5_ReplicaChecks.sql
EOF
chmod +x "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_Scripts.sh"

# Copy outputs
for out in portfolio-5-distributed-cloud/output/*.txt; do
    bname=$(basename "$out")
    cp "$out" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/Output/${SURNAME}_${FIRSTNAME}_P5_${bname}"
done

# Copy P5 Screenshots
for img in portfolio-5-distributed-cloud/screenshots/*.png; do
    if [ -f "$img" ]; then
        cp "$img" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/Screenshots/"
    fi
done

# Copy nexora_dump.sql as Bamishaye_Favour_P5_NexoraDump.sql
cp "portfolio-5-distributed-cloud/nexora_dump.sql" "${TARGET_DIR}/Portfolio_5_Distributed_And_Cloud/${SURNAME}_${FIRSTNAME}_P5_NexoraDump.sql"

echo "[+] Portfolio 5 files packaged."

# 10. Clean any macOS metadata files (.DS_Store)
find "${TARGET_DIR}" -name ".DS_Store" -delete

# 11. Strict Name Validation Check
echo "[*] Validating naming conventions (Checking for spaces and generic terms)..."
INVALID_FILES=0

# Check for spaces in filenames or directory names
while IFS= read -r -d '' item; do
    echo "[!] ERROR: Found space in path: $item"
    INVALID_FILES=$((INVALID_FILES + 1))
done < <(find "${TARGET_DIR}" -name "* *" -print0)

# Check that all files strictly adhere to Surname_Firstname_ convention and have no generic filenames
for generic in "Assignment" "Final_File" "Final File" "Project" "Document"; do
    while IFS= read -r -d '' item; do
        bname=$(basename "$item")
        # Check if file has generic name as standalone or starts without student name
        if [[ "$bname" =~ ^(${generic})\. ]] || [[ "$bname" =~ ^(${generic})_ ]]; then
            echo "[!] ERROR: Generic filename detected: $item"
            INVALID_FILES=$((INVALID_FILES + 1))
        fi
    done < <(find "${TARGET_DIR}" -type f -print0)
done

# Ensure all files in the root and subdirectories start with Bamishaye_Favour_
while IFS= read -r -d '' item; do
    bname=$(basename "$item")
    if [[ ! "$bname" =~ ^${SURNAME}_${FIRSTNAME}_ ]] && [[ "$bname" != ".DS_Store" ]]; then
        echo "[!] WARNING: File does not start with '${SURNAME}_${FIRSTNAME}_': $item"
        INVALID_FILES=$((INVALID_FILES + 1))
    fi
done < <(find "${TARGET_DIR}" -type f -print0)

if [ "$INVALID_FILES" -gt 0 ]; then
    echo "[!] Validation failed with $INVALID_FILES issues. Please review before proceeding."
    exit 1
else
    echo "[+] All files strictly conform to ${SURNAME}_${FIRSTNAME}_DocumentType (0 spaces, 0 generic filenames)."
fi

# 12. Create the Zipped Archive
echo "[*] Building ZIP archive: ${ZIP_NAME}..."
zip -r "${ZIP_NAME}" "${TARGET_DIR}" > /dev/null

# 13. Verify Size & Report Status
ZIP_SIZE_BYTES=$(stat -f%z "${ZIP_NAME}")
ZIP_SIZE_MB=$(echo "scale=2; ${ZIP_SIZE_BYTES} / (1024 * 1024)" | bc)
FILE_COUNT=$(find "${TARGET_DIR}" -type f | wc -l | tr -d ' ')

echo "======================================================================"
echo " PACKAGING COMPLETE & VALIDATED SUCCESSFULLY!"
echo "======================================================================"
echo " Root Directory Inside Zip: ${TARGET_DIR}/"
echo " Total Files Packaged:     ${FILE_COUNT} files"
echo " Final Archive File:       ${ZIP_NAME}"
echo " Final Archive Size:       ${ZIP_SIZE_MB} MB (Limit: 100 MB)"
echo " Standalone ReadME File:   ${README_TXT} (Ready for Field 3 upload)"
echo "======================================================================"

if (( $(echo "${ZIP_SIZE_MB} > 100.0" | bc -l) )); then
    echo "[!] CRITICAL WARNING: Archive size exceeds 100 MB limit!"
    exit 1
else
    echo "[✓] Archive is safely under the 100 MB limit."
fi
