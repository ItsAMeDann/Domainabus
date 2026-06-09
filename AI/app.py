import os

from flask import Flask, request, jsonify
import random

app = Flask(__name__)

@app.route('/tes-api', methods=['GET'])
def check_status():
    print("[DEBUG] GET /tes-api ping received.")
    return jsonify({"Status": "API Berhasil Diakses!", "Message": "Siap menerima request!"})

@app.route('/ai-predict', methods=['POST'])
def ai_logic():
    data = request.get_json()
    if not data:
        print("[DEBUG] POST /ai-predict received empty body!")
        return jsonify({"error": "Empty payload"}), 400

    print("[DEBUG] Received POST payload:")
    print(data)

    # Read current wave number (checking both lowercase and uppercase names)
    current_wave = data.get("wave_number", data.get("Wave Number", 1))
    
    # Read weapon usage telemetry (checking both keys)
    weapon_usage = data.get("weapon_telemetry", data.get("Weapon_Usage", {}))
    
    # Map weapon names to match dominant checks (from Godot format or legacy format)
    mapped_weapon_usage = {
        "basic-gun": weapon_usage.get("beta_lactam_shots", weapon_usage.get("basic-gun", 0)),
        "shotgun": weapon_usage.get("macrolide_pulse_shots", weapon_usage.get("shotgun", 0)),
        "grenade-launcher": weapon_usage.get("cipro_blast_shots", weapon_usage.get("grenade-launcher", 0))
    }

    previous_enemies = data.get("survived_pathogens", data.get("Previous-Enemies", []))
    next_wave = current_wave + 1
    spawn_count = 10 + (next_wave * 5)

    # 1. Define allowed classes based on the next wave number
    if next_wave == 1:
        allowed_classes = ["bacteriophage"]
    elif next_wave == 2:
        allowed_classes = ["bacteriophage", "spirillum"]
    else:
        allowed_classes = ["bacteriophage", "spirillum", "coccus"]

    # 2. Determine dominant weapon and counter class
    dominant_weapon = max(mapped_weapon_usage, key=mapped_weapon_usage.get)
    
    # Sometimes randomize the counter class to break monotony (25% chance)
    if random.random() < 0.25:
        counter_class = random.choice(allowed_classes)
        print(f"[DEBUG] Monotony breaker triggered. Randomized dominant class to: {counter_class}")
    else:
        if dominant_weapon == "shotgun":
            counter_class = "bacteriophage"
        elif dominant_weapon == "grenade-launcher":
            counter_class = "spirillum"
        else:
            counter_class = "coccus"

    # Make sure counter class is actually unlocked/allowed
    if counter_class not in allowed_classes:
        counter_class = allowed_classes[-1]

    print(f"[DEBUG] Next Wave: {next_wave}, Allowed Classes: {allowed_classes}, Dominant Weapon: {dominant_weapon}, Target Counter Class: {counter_class}")

    # ==========================================
    # DYNAMIC SPAWN INTERVAL LOGIC
    # ==========================================
    # Define baseline intervals for your pathogens
    base_intervals = {
        "bacteriophage": 3.0,
        "spirillum": 3.0,
        "coccus": 5.0
    }
    min_intervals = {
        "bacteriophage": 0.6,
        "spirillum": 0.5,
        "coccus": 0.8
    }

    spawn_config = {}
    for pathogen in ["bacteriophage", "spirillum", "coccus"]:
        # Gradually shrink interval based on wave progression (10% decay per wave)
        decay_factor = 0.93 ** (next_wave - 1)
        scaled_interval = base_intervals[pathogen] * decay_factor
        
        # If it's the dominant counter counter-class, make them spawn significantly faster
        weight = 1.0
        if pathogen == counter_class:
            scaled_interval *= 0.5  # Cut interval in half to swarm the player
            weight = 2.0            # Increase spawn ratio weight for the manager burst math
            
        # Ensure it never drops below absolute chaotic thresholds
        final_interval = max(min_intervals[pathogen], scaled_interval)
        
        spawn_config[pathogen] = {
            "interval": round(final_interval, 2),
            "weight": weight
        }

    # ==============================
    # GENETIC ALGORITHM (Kept intact)
    # ==============================
    pathogen_population = []
    class_counts = {"bacteriophage": 0, "spirillum": 0, "coccus": 0}

    # Helper function to add a pathogen while strictly capping at 5 per class type
    def try_add_pathogen(class_name, mutated_beta, mutated_macro, mutated_cipro):
        c_type = class_name.lower()
        if class_counts.get(c_type, 0) >= 5:
            # Find alternative allowed class that has space
            alternative = None
            for ac in allowed_classes:
                if class_counts.get(ac, 0) < 5:
                    alternative = ac
                    break
            if alternative:
                class_name = alternative
                c_type = alternative
            else:
                return False  # No available class has space
                
        class_counts[c_type] = class_counts.get(c_type, 0) + 1
        pathogen_population.append({
            "id": len(pathogen_population) + 1,
            "class_type": class_name,
            "has_beta_lactam": mutated_beta,
            "res_macrolide": mutated_macro,
            "res_cipro": mutated_cipro,
            "genes": {
                "res_beta_lactam": mutated_beta,
                "res_macrolide": mutated_macro,
                "res_cipro": mutated_cipro
            }
        })
        return True

    # ==============================
    # GENETIC ALGORITHM
    # ==============================

    if not previous_enemies:
        print("[DEBUG] No previous enemy telemetry. Initializing base genetic population.")
        for i in range(spawn_count):
            if len(allowed_classes) > 1:
                choices = []
                weights = []
                for c in allowed_classes:
                    choices.append(c)
                    if c == counter_class:
                        weights.append(0.6)
                    else:
                        weights.append(0.4 / (len(allowed_classes) - 1))
                class_type = random.choices(choices, weights=weights)[0]
            else:
                class_type = allowed_classes[0]

            mutated_beta = round(random.uniform(0.1, 0.4), 2)
            mutated_macro = round(random.uniform(0.1, 0.4), 2)
            mutated_cipro = round(random.uniform(0.1, 0.4), 2)
            
            if not try_add_pathogen(class_type, mutated_beta, mutated_macro, mutated_cipro):
                break
    else:
        print(f"[DEBUG] Evolving population using {len(previous_enemies)} survived pathogens.")
        # Calculate fitness
        for enemy in previous_enemies:
            survival_time = enemy.get("survival_time", enemy.get("survival_time_seconds", 0.0))
            damage_dealt = enemy.get("damage_dealt", 0.0)
            enemy['fitness'] = survival_time + (damage_dealt * 2)

        # Sort by fitness descending
        previous_enemies.sort(key=lambda x: x['fitness'], reverse=True)
        
        # Track class types represented in survived parents
        survived_classes = set(enemy.get("class_type", "").lower() for enemy in previous_enemies if enemy.get("class_type"))
        
        # Identify if we need to inject a newly unlocked class
        newly_unlocked_class = None
        for c in allowed_classes:
            if c not in survived_classes:
                newly_unlocked_class = c
                break

        print(f"[DEBUG] Survived classes: {survived_classes}, Newly unlocked to inject: {newly_unlocked_class}")

        for i in range(spawn_count):
            is_injection = False
            # Force inject newly unlocked classes to ensure they appear in the wave
            if newly_unlocked_class and (i < max(3, int(spawn_count * 0.25))):
                is_injection = True
            # 15% random mutation/migration rate to keep diversity
            elif random.random() < 0.15:
                is_injection = True

            if is_injection:
                if newly_unlocked_class and random.random() < 0.7:
                    class_type = newly_unlocked_class
                else:
                    class_type = random.choice(allowed_classes)
                
                # Base genes for new migration injection: average of top parents, or random
                if len(previous_enemies) > 0:
                    top_parent = previous_enemies[0]
                    p_genes = top_parent.get("genes", top_parent)
                    base_beta = p_genes.get("res_beta_lactam", 0.2)
                    base_macro = p_genes.get("res_macrolide", 0.2)
                    base_cipro = p_genes.get("res_cipro", 0.2)
                else:
                    base_beta = random.uniform(0.1, 0.4)
                    base_macro = random.uniform(0.1, 0.4)
                    base_cipro = random.uniform(0.1, 0.4)
            else:
                # Normal breeding from top parents
                parent1 = previous_enemies[0]
                parent2 = previous_enemies[1] if len(previous_enemies) > 1 else parent1
                
                # Inherit class type from fitter parent
                class_type = parent1.get("class_type", "bacteriophage").lower()
                if class_type not in allowed_classes:
                    class_type = random.choice(allowed_classes)
                
                p1_genes = parent1.get("genes", parent1)
                p2_genes = parent2.get("genes", parent2)

                base_beta = (p1_genes.get("res_beta_lactam", parent1.get("has_beta_lactam", 0.1)) + 
                             p2_genes.get("res_beta_lactam", parent2.get("has_beta_lactam", 0.1))) / 2
                base_macro = (p1_genes.get("res_macrolide", parent1.get("res_macrolide", 0.1)) + 
                              p2_genes.get("res_macrolide", parent2.get("res_macrolide", 0.1))) / 2
                base_cipro = (p1_genes.get("res_cipro", parent1.get("res_cipro", 0.1)) + 
                              p2_genes.get("res_cipro", parent2.get("res_cipro", 0.1))) / 2

            # Mutate (plus minus 0.05) clamped to [0.0, 0.95]
            mutated_beta = round(max(0.0, min(0.95, base_beta + random.uniform(-0.05, 0.05))), 2)
            mutated_macro = round(max(0.0, min(0.95, base_macro + random.uniform(-0.05, 0.05))), 2)
            mutated_cipro = round(max(0.0, min(0.95, base_cipro + random.uniform(-0.05, 0.05))), 2)
                
            if not try_add_pathogen(class_type, mutated_beta, mutated_macro, mutated_cipro):
                # If adding failed because all allowed classes are full, try to find any that has space
                added = False
                for ac in allowed_classes:
                    if try_add_pathogen(ac, mutated_beta, mutated_macro, mutated_cipro):
                        added = True
                        break
                if not added:
                    break

    response_body = {
        "next_wave_number": next_wave,
        "spawn_count": len(pathogen_population),
        "pathogen_population": pathogen_population,
        "spawn_config": spawn_config,
        "dominant_threat": counter_class
    }
    
    print(f"[DEBUG] Evolved population counts: {class_counts}")
    print(f"[DEBUG] Sending prediction response: next_wave={next_wave}, spawn_count={len(pathogen_population)}")
    print(f"[DEBUG] Dynamic Configs Generated: {spawn_config}")
    print(f"[DEBUG] Target Counter Class sent: {counter_class}")
    return jsonify(response_body)

if __name__ == '__main__':
    app.run()