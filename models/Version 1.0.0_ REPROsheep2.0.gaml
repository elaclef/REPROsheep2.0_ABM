/***
* Name: REPROsheep20
* Author: laclefel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model REPROsheep20


//----------------------------------------------------------------------------
// GLOBAL ATTRIBUTS AND PARAMETERS
//----------------------------------------------------------------------------
global {
	string scenario <- "scenar";
	
	reflex scenarii {
		
		if (scenario = "scenar0" or scenario = "scenar2" or scenario = "scenar4") {
			AI <- true;
			hormon_shot <- true;
			male_female_ratio<-1/55;
		}

		if (scenario = "scenar1" or scenario = "scenar3" or scenario = "scenar5") {
			AI <- true;
			hormon_shot <- false;
			male_female_ratio<-1/25;
		}


	}

	//////Loading all external source files///////
	csv_file data <- csv_file("../includes/inputs/flock.csv", ";", true);
	csv_file data2<- csv_file("../includes/inputs/Management_dates.csv", ";", true);
	csv_file data3 <- csv_file("../includes/inputs/All_parametersvalues.csv", ";", true);

	
	// Création de matrices associées
	matrix dates <- matrix(data2);
	matrix all_parameters <- matrix(data3);
	

	//INITIALISATION ET VISUALISATION DES AGENTS//
	float marge <- 1.0 parameter: "marge entre icons" category: "visualisation";
	float largeur_brebis <- 60.0 parameter: "largeur de l'espace brebis" category: "visualisation";
	float icon_size_max <- 2.0 parameter: "taille max des icons" category: "visualisation";
	float icon_size;
	map<string, rgb> ewes_state_color <- ["in anoestrus"::#blue, "in heat"::#red, "gestating"::#orange, "lactating"::#purple];
	map<string, rgb> rams_state_color <- ["resting"::#yellow, "active"::#violet];
	geometry background_ewes;
	geometry background_rams;
	geometry background_breeder;

	init {
		create farmer number: 1 {

			create ewe from: data with: [age::int(get("Age")), BCS::float(get("BCS")), lact_num::int(get("Lact_num")), Ctl::map<int, float>(get("CLO"))] {
				myself.my_ewes << self;
				my_farmer <- myself;
				days_since_lambing <- int(gauss(200.0, 30.0));
				estimated_total_milk_production <-min(450.0, max(50.0,gauss(350.0, 80.0)));
				newborn <- false;
				nutrition_state <- "maintenance";
				renew <- false;
				weight <- 75.0;
				TB_inti_value<-60.7;
				TP_init_value<-45.9;
				if (age = 0) {
					days_since_lambing <- 0;
					renew <- true;
					estimated_total_milk_production <- 0.0;
					nutrition_state <- "fmaintenance";
					weight <- 47.0;
				}

			}

			flock_size <- length(my_ewes);
			write "flock_size: " + flock_size;
			taille_troupeau[milk_prod_campaign_number] <- flock_size;
			create ram number: round(length(ewe)*male_female_ratio) {
				myself.my_rams << self;
				newborn <- false;
				my_farmer <- myself;
				age <- rnd(2, 4); 
				state <- "male";
			}


		}

		do compute_visualisation;
	}

	action compute_visualisation {
		ask farmer {
			location <- {10, 8};
		}

		float y_size <- 80.0;
		icon_size <- icon_size_max;
		int nb_brebis <- length(ewe);
		int nb_beliers <- length(ram);
		int max_cpt_x <- int((largeur_brebis - 4) / (icon_size + marge));
		int max_cpt_y <- int(y_size / (icon_size + marge));
		int nb_places <- max_cpt_x * max_cpt_y;
		loop while: nb_brebis > nb_places {
			icon_size <- icon_size * 0.9;
			max_cpt_x <- int((largeur_brebis - 4) / (icon_size + marge));
			max_cpt_y <- int(y_size / (icon_size + marge));
			nb_places <- max_cpt_x * max_cpt_y;
		}

		int cpt_x;
		int cpt_y;
		ask ewe {
			location <- {5 + icon_size + cpt_x * (icon_size + marge), 14 + icon_size + cpt_y * (icon_size + marge)};
			cpt_x <- cpt_x + 1;
			if (cpt_x > max_cpt_x) {
				cpt_x <- 0;
				cpt_y <- cpt_y + 1;
			}

		}

		float yy <- int((world.shape.width - largeur_brebis - (icon_size * 2))) - 3 * marge - 2 * icon_size;
		max_cpt_x <- int((yy - 5) / (icon_size + marge));
		cpt_x <- 0;
		cpt_y <- 0;
		ask ram {
			location <- {5 + largeur_brebis + icon_size * 2 + cpt_x * (icon_size + marge), 14 + icon_size + cpt_y * (icon_size + marge)};
			cpt_x <- cpt_x + 1;
			if (cpt_x > max_cpt_x) {
				cpt_x <- 0;
				cpt_y <- cpt_y + 1;
			}

		}

		background_breeder <- rectangle(90, 10) at_location {50, 8};
		background_ewes <- rectangle(largeur_brebis, y_size) at_location {largeur_brebis / 2 + 5, y_size / 2 + 14};
		background_rams <- rectangle(yy, y_size) at_location {largeur_brebis + 2 * marge + 2 * icon_size_max + yy / 2, y_size / 2 + 14};
	}

	reflex update_visualisation {
		do compute_visualisation;
	}


	//Starting inputs//
	date starting_date<-date(2017, 6, 19);
	int dur_sim <- 808; //= 1 production season
	float step <- 12 #hours;
	bool AI <- true;
	bool hormon_shot <- true;
	date cut_date <- date(2017, 5, 1); // date of the first cut
	date grazed_date_beg <- date(2017, 4, 8); // date of the beginning of the grazed period 
	date grazed_date_end <- date(2017, 11, 15); // date of the end of the grazed period	

	///PARAMETERS RELATIVE TO EWE REPRODUCTION ///////////
	int flock_size;
	float easy_lambing <- float(all_parameters[2, 0]); /*proba to lamb without any complication */
	float proba_abortion <- float(all_parameters[2, 1]);
	float proba_seasonnal_oestrus <- float(all_parameters[2, 2]);
	float synchronization_rate <- float(all_parameters[2, 3]);
	float to_portee_2 <- float(all_parameters[2, 4]); //  proba to have a litter size= 2
	float to_portee_3 <- float(all_parameters[2, 16]); // proba to have a litter size= 3
	float mortality_rate <- float(all_parameters[2, 14]);
	


	///PARAMETERS RELATIVE TO EWE LACTATION ////////////
	float prod_min <- float(all_parameters[2, 5]);
	float ewelamb_initial_milk_prod_mean <- float(all_parameters[2, 6]); 
	float ewe_initial_milk_prod_mean <- float(all_parameters[2, 7]);
	float proba_hp <- float(all_parameters[2, 8]);

	///PARAMETERS RELATIVE TO HUMAN MANAGEMENT /////////
	date flock_milking_start<-date(2017, 12, 30);
	date end_delivery_date;
	int culling_age <- int(all_parameters[2, 9]);
	float proba_AI_sucess <- float(all_parameters[2, 10]);
	float young_proba_AI_sucess <- float(all_parameters[2, 20]);
	float turnover_rate <- float(all_parameters[2, 11]);
	int ewesonly_free_mating_duration <- int(all_parameters[2, 12]); 
	float genetic_gain_for_milk_prod <- float(all_parameters[2, 13]);
	int male_effect_duration <- int(all_parameters[2, 15]); 
	float AI_rate <- float(all_parameters[2, 17]); 
	float youngs_AI_rate <- float(all_parameters[2, 18]); 
	float youngs_synchronization_rate <- float(all_parameters[2, 19]);
	float EffPDI <- 0.58; 
	int milk_prod_campaign_number <- 0;
	int number_of_milk_monitoring <- 4;
	float detection_rate<-1.0;
	float male_female_ratio<-1/55;
	map<string, float> total_energy_intake;
	map<string, float> total_protein_intake;

	// OUTPUTS DEFINITION
	// declaration of output variables:
	map<string, float> grazed_day; // map of monthly grazed days per surface
	map<string, float> grazed_day_ugb; // map of monthly grazed days per ugb
	map<string, float> feed_distributed; /*to stock distributed feed quantity */
	map<int, float> htmp; /*total milk prod of the flock */
	map<date, float> flock_bes_UFL;
	map<date, float> flock_bes_PDI;

	///////INITIALISATION OUTPUT DISPLAYS

	int number_of_ewes_starting_heating;
	int number_of_ewelamb_starting_heating;
	int number_of_ewes_coming_back_into_heat;
	int number_of_gestating_females;
	int number_of_ewes_lambing;
	int number_of_ewes_entering_milking;
	int young_ewes_sales;
	int young_ram_sales;
	float sales_youngs;
	int nb_culled_ad; // nb of culled females
	int nb_culled_ad_tot; // nb of culled females+males
	map<date, int> nb_dry_or_maintening_ewes;
	map<date, int> nb_dry_or_maintening_ewelambs;
	map<date, int> nb_gestating_ewes;
	map<date, int> nb_gestating_ewelambs;
	map<date, int> nb_lactating_ewes;
	map<date, int> nb_lactating_ewelambs;
	map<date, int> nb_suckling_ewes;
	map<date, int> nb_suckling_ewelambs;

	float htmp_count_day <- 0.0;
	list<float> htmp_count;
	int total_lambing_count;
	map<date, float> htmp_count2;
	int lambing_count_day <- 0;
	list<int> lambing_count <- [];
	map<date, int> lambing_count2;
	map<date, float> bes_UFL_MY_moy_ewe;
	map<date, float> bes_UFL_MY_moy_ewelamb;
	map<date, float> bes_UFL_gest_moy_ewe;
	map<date, float> bes_UFL_gest_moy_ewelamb;
	map<date, float> bes_UFL_ent;
	map<date, float> bes_UFL_ent_ewelamb;
	map<date, float> besUFL_suck_flock_ewe;
	map<date, float> besUFL_suck_flock_ewelamb;

	reflex lambing_counting when: every(#day) {
		lambing_count <+ lambing_count_day;
		lambing_count2[current_date] <- lambing_count_day;
		lambing_count_day <- 0;
	}

	reflex htmp_calcul when: every(#day) {
		htmp_count <+ htmp_count_day;
		htmp_count2[current_date] <- htmp_count_day;
		htmp_count_day <- 0.0;
	}

	reflex reset_donnees when: every(1 #day) {
		number_of_ewes_starting_heating <- 0;
		number_of_ewelamb_starting_heating <- 0;
		number_of_ewes_coming_back_into_heat <- 0;
		number_of_gestating_females <- 0;
		number_of_ewes_lambing <- 0;
		number_of_ewes_entering_milking <- 0;
	}

	reflex maj_year1 when: every(1 #years + 1 #s) {
		young_ewes_sales <- 0;
		young_ram_sales <- 0;
	}

	

	reflex maj_year2 when: current_date = ending_simulation {
		sales_youngs <- 0.0;
		nb_culled_ad <- 0;
		nb_culled_ad_tot <- 0;
	}


	reflex sauvegarde_par_annees when: cycle = dur_sim {
		
		save self.name + "," + self.scenario + "," + self.total_lambing_count  type: text to: "Scenar_outputs/Results_tlc_campagne.txt" rewrite: false;
		loop d over: lambing_count2.keys {
			save self.name + "," + self.scenario + "," + d + "," + self.lambing_count2[d] to: "Scenar_outputs/Results_LC_day.txt" rewrite: false
			type: text;
		}
			save self.name + "," + self.scenario + "," + self.htmp type: text to: "Scenar_outputs/Results_HTMP_campagne.txt" rewrite: false;
		loop p over: htmp_count2.keys {
			save self.name + "," + self.scenario + "," + p + "," + self.htmp_count2[p] to: "Scenar_outputs/Results_HTMP_day_campagne.txt" rewrite: false
			type: text;
		}

		loop e over: nb_dry_or_maintening_ewes.keys {
			save
			self.name + "," + self.scenario + "," + e + "," + self.nb_dry_or_maintening_ewes[e] + "," + self.nb_gestating_ewes[e] + "," + self.nb_suckling_ewes[e] + "," + self.nb_lactating_ewes[e]
			to: "Scenar_outputs/Results_phys_stage_ewes.txt" rewrite: false type: text;
			save self.name + "," + self.scenario + "," + e + "," + self.flock_bes_PDI[e] + "," + self.flock_bes_UFL[e] to:
			"Scenar_outputs/Results_nutritional_requirements.txt" rewrite: false type: text;
		}

		loop f over: nb_dry_or_maintening_ewelambs.keys {
			save
			self.name + "," + self.scenario + "," + f + "," + self.nb_dry_or_maintening_ewelambs[f] + "," + self.nb_gestating_ewelambs[f] + "," + self.nb_suckling_ewelambs[f] + "," + self.nb_lactating_ewelambs[f]
			to: "Scenar_outputs/Results_phys_stage_ewelambs.txt" rewrite: false type: text;
		}

	}
	
	

	reflex ending_simulation when: cycle = dur_sim {
		do pause;
	}

}
////////////Fin de la partie global//////////////////////

//----------------------------------------------------------------------------
// AGENTS SHEEP :
//----------------------------------------------------------------------------
species sheep {
	date birth_date; 
	int age;
	float weight; 
	bool newborn <- true;
	bool culling_for_age <- false; 
	bool renew;
	svg_file icon;
	farmer my_farmer;
	string nutrition_state;

	reflex aging when: cycle != 0 and ((current_date = my_farmer.ram_introduction) or (current_date = my_farmer.pose_eponge)) {
		age <- age + 1;
		ask (ewe where each.newborn) {
			renew <- true;
		}

		ask (ewe where (each.renew and each.age > 0)) {
			renew <- false;
		}

		newborn <- false;
	}

	reflex youngs_nutrition_state when: every(#day) and age < 0 and not renew {
		nutrition_state <- "growing";
	}

	rgb couleur {
		return #white;
	}

	aspect default {
		draw icon size: icon_size / 2 + (icon_size / 2 * age / 10) color: couleur() rotate: 180; 
	}

}

//----------------------------------------------------------------------------
// AGENTS RAM :
//----------------------------------------------------------------------------
species ram parent: sheep {
	svg_file icon <- svg_file("../includes/ram.svg");
	rgb couleur <- #yellow;
	bool active <- false;
	bool active_for_ewelambs <- false;
	float proba_mating_success <- 0.5;
	string state <- "resting";
	rgb couleur {
		return rams_state_color[state];
	}

	init {
		nutrition_state <- "male";
	}

	reflex mating when: every(#day) and active {
		list<ewe> empty_ewe <- ewe where (each.age >= 1 and each.in_heat and not each.gestating);
		if not empty(empty_ewe) {
			ask (empty_ewe) {
				gestating <- flip(myself.proba_mating_success);
				if (gestating) {
					gestating <- true;
					state <- "gestating";
					couleur <- #orange;
					start_gestation <- current_date;
					number_of_gestating_females <- number_of_gestating_females + 1;
					in_heat <- false;
					first_heat <- false;
				}

			}

		}

	}

	reflex mating_ewelambs when: every(#day) and active_for_ewelambs {
		list<ewe> empty_ewelambs <- ewe where (each.renew and each.in_heat and not each.gestating);
		if not empty(empty_ewelambs) {
			ask (empty_ewelambs) {
				gestating <- flip(myself.proba_mating_success);
				if (gestating) {
					gestating <- true;
					state <- "gestating";
					couleur <- #orange;
					start_gestation <- current_date;
					number_of_gestating_females <- number_of_gestating_females + 1;
					in_heat <- false;
					first_heat <- false;
				}

			}

		}

	}

}

//----------------------------------------------------------------------------
// AGENTS EWE :
//----------------------------------------------------------------------------
species ewe parent: sheep {
	svg_file icon <- svg_file("../includes/ewe.svg");
	rgb couleur <- #blue;
	bool in_anoestrus <- true;
	bool in_heat <- false;
	bool first_heat <- false;
	bool gestating <- false;
	bool gave_birth <- false;
	bool suckling <- false;
	bool lactating <- false;
	bool cyclic <- false;
	bool MER <- false;
	bool abortion <- false;
	bool culling <- false; 
	bool latecomer <- false;
	bool health_problem <- false;
	bool to_be_inseminate <- false;
	bool culling_for_perf <- false;
	float BCS;
	float TB;
	float TP;
	float TB_inti_value;
	float TP_init_value;
	float ewe_initial_milk_prod <- min(4.5, max(1.0, gauss(ewe_initial_milk_prod_mean, 0.9))); 
	float ewelamb_initial_milk_prod <- min(4.5, max(1.0, gauss(ewelamb_initial_milk_prod_mean, 0.9))); 
	float proba_cyclic;
	float proba_MER;
	map<int, float> Ctl;
	map<int, float> Constante;
	float besUFL_gest;
	float besUFL_suck;
	float besPDI_suck;
	float besUFL_maint;
	float besPDI_maint;
	float besUFL_MY;
	float besUFL_gain;
	float besPDI_MY;
	float besPDI_gest;
	float bes_UFL_tot;
	float bes_PDI_tot;
	int foetusweigth <- 7; //Average litter weight for a 70-75kg Lacaune ewe with 2 lambs (INRAtion)
	float weight_gain_of_youngs_during_suck <- 350.0; // daily weight gain during the first 3 weeks of lactation (in g/d)
	float BCSvariation;
	int number_of_milking_days;
	int gestating_week;
	int week_before_lambing;
	int lact_num;
	map<int, list<float>> milk_prod; /*maping milk prod  */
	float estimated_total_milk_production;
	date start_gestation;
	date abortion_date;
	map<int, date> start_milking;
	date start_heating;
	map<int, date> end_of_milking_date;
	map<int, date> lambing_date;
	int day_of_first_heat;
	int day_of_first_heat_ewelamb <- rnd(0, 17);
	int day_of_first_heat_with_AI <- 1;
	int gestation_duration <- int(min(157.0, max(145.0, gauss(147.0, 5.0)))); 
	int day_of_abortion <- rnd(5, 140);
	int suckling_duration <- 32; 
	int days_since_lambing;
	string state <- "in anoestrus";
	bool to_portee <- false; 
	bool to_portee3 <- false; 
	int lit_size <- 1; 
	rgb couleur {
		return ewes_state_color[state];
	}

	reflex calcul_maintenance_needs when: every(#day) {
		bes_UFL_tot <- besUFL_maint + besUFL_gest + besUFL_suck + besUFL_MY;
		bes_PDI_tot <- besPDI_maint + besPDI_gest + besPDI_suck + besPDI_MY;
		if (gestating and lact_num != 0 and current_date between (start_gestation, start_gestation add_days 150)) {
			BCSvariation <- 0.5; // theoretical change in BCS during this period
			weight <- weight + 0.033; // equivalent (kg) of BCS variation(+1 pt of BCS <=> +13% of body weight
			besUFL_maint <- (0.033 * (weight) ^ 0.75) + 0.43 * weight * (BCSvariation / 150); //150=5 months
			besPDI_maint <- (2.5 * (weight) ^ 0.75) + besUFL_maint * 33;
			if (renew) {
				weight <- weight + 0.15; 
				besUFL_maint <- besUFL_maint + (0.28 * (150 / 100) * 0.956);
				besPDI_maint <- besPDI_maint + 0.130 * (150 / 0.58);
			}

		}

		if (renew and gestating and current_date between (start_gestation, start_gestation add_days 150)) {
			if (age = 0 and lact_num = 0) {
				weight <- weight + 0.15; 
				besUFL_maint <- (0.033 * (weight) ^ 0.75) + (0.28 * (150 / 100) * 0.956); 
				besPDI_maint <- (2.5 * (weight) ^ 0.75) + 0.130 * (150 / 0.58);
			}

		} else {
			besUFL_maint <- (0.033 * (weight) ^ 0.75);
			besPDI_maint <- (2.5 * (weight) ^ 0.75);
		}

	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	reflex calcul_estimated_prod when: current_date = my_farmer.ram_introduction and gave_birth {
		estimated_total_milk_production <- Constante[0] * (Ctl[0] * 0.001);
		loop i from: 1 to: number_of_milk_monitoring {
			estimated_total_milk_production <- estimated_total_milk_production + (Constante[i] * (Ctl[i - 1] + Ctl[i]) * (0.001 / 2));
		}

	}

	reflex ewelamb_entering_in_heat when: (((not hormon_shot and renew) or (latecomer)) and (not first_heat and in_anoestrus and not gestating)) and
	((current_date = my_farmer.ewe_lamb_start_mating_date add_days day_of_first_heat_ewelamb) or (current_date = my_farmer.second_ram_intro_date add_days day_of_first_heat_ewelamb))
	{
		if (current_date.month between (2, 7)) {
			first_heat <- flip(0.5);
		}

		if (current_date.month between (6, 9)) {
			first_heat <- flip(0.8);
		}

		if (current_date.month = 9 or current_date.month = 10 or current_date.month = 11 or current_date.month = 12) {
			first_heat <- flip(0.95);
		}

		if (first_heat) {
			start_heating <- current_date;
			in_heat <- true;
			in_anoestrus <- false;
			state <- "in heat";
			latecomer <- false;
			number_of_ewelamb_starting_heating <- number_of_ewelamb_starting_heating + 1;
		}

	}

	reflex ewelamb_entering_in_heat_with_hormones when: renew and hormon_shot and in_anoestrus and not first_heat and not gestating and
	(current_date = my_farmer.retrait_eponge_ewelamb add_days day_of_first_heat_with_AI) {
		first_heat <- flip(youngs_synchronization_rate);
		if (first_heat) {
			start_heating <- current_date;
			in_heat <- true;
			in_anoestrus <- false;
			state <- "in heat";
			number_of_ewelamb_starting_heating <- number_of_ewelamb_starting_heating + 1;
		}

	}

	reflex being_cyclic_before_male_effect when: not hormon_shot and age >= 1 and not culling_for_age and not culling_for_perf and (current_date = my_farmer.ram_introduction) and
	in_anoestrus {
		if (my_farmer.mating_period = "early" and (BCS <= 2.0) ) {
				proba_cyclic <-
				exp(0.007 * estimated_total_milk_production + 0.103 * age + 0.008 * days_since_lambing - 0.002 * last(Ctl) - 2.732) / (1 + exp(0.007 * estimated_total_milk_production + 0.103 * age + 0.008 * days_since_lambing - 0.002 * last(Ctl) - 2.732));
			}

			if (my_farmer.mating_period = "early" and BCS > 3.0) {
				proba_cyclic <-
				exp(1.212 + 0.007 * estimated_total_milk_production + 0.103 * age + 0.008 * days_since_lambing - 0.002 * last(Ctl) - 2.732) / (1 + exp(1.212 + 0.007 * estimated_total_milk_production + 0.103 * age + 0.008 * days_since_lambing - 0.002 * last(Ctl) - 2.732));
			} 
			if (my_farmer.mating_period = "early" and BCS between( 2.0,3.1)) {
				proba_cyclic <-
				exp(0.592 + 0.007 * estimated_total_milk_production + 0.103 * age + 0.008 * days_since_lambing - 0.002 * last(Ctl) - 2.732) / (1 + exp(0.592 + 0.007 * estimated_total_milk_production + 0.103 * age + 0.008 * days_since_lambing - 0.002 * last(Ctl) - 2.732));
			}

		if (my_farmer.mating_period = "late") {
			if (current_date.month between (5, 9)) {
				proba_cyclic <- 0.8;
			} 
			if (current_date.month between (8, 12)) {
				proba_cyclic <- 1.0;
			}

		}
		
		cyclic <- flip(proba_cyclic);
		
		if (cyclic) {
			day_of_first_heat <- rnd(0, 17);
		}

	}
	
	reflex responding_to_male_effect when: not hormon_shot and age >= 1 and not culling_for_age and not culling_for_perf and (current_date = my_farmer.ram_introduction add_days 10)
	and not cyclic {
		if (BCS <= 2.0) {
			proba_MER <-
			exp(0.011 * estimated_total_milk_production + 0.276 * age - 0.002 * last(Ctl) - 1.964) / (1 + exp(0.011 * estimated_total_milk_production + 0.276 * age - 0.002 * last(Ctl) - 1.964));
		}

		if (BCS > 3.0) {
			proba_MER <-
			exp(2.871 + 0.011 * estimated_total_milk_production + 0.276 * age - 0.002 * last(Ctl) - 1.964) / (1 + exp(2.871 + 0.011 * estimated_total_milk_production + 0.276 * age - 0.002 * last(Ctl) - 1.964));
		} else {
			proba_MER <-
			exp(1.745 + 0.011 * estimated_total_milk_production + 0.276 * age - 0.002 * last(Ctl) - 1.964) / (1 + exp(1.745 + 0.011 * estimated_total_milk_production + 0.276 * age - 0.002 * last(Ctl) - 1.964));
		}

		MER <- flip(proba_MER);
		if (MER) {
			if (flip(0.5)) {
				day_of_first_heat <- int(min(22, max(14, gauss(18, 3))));
			} else {
				day_of_first_heat <- int(min(28, max(20, gauss(24, 3))));
			}

		}

	}

	reflex starts_heating when: every(#day) and age >= 1 and not culling_for_age and not culling_for_perf and not first_heat and in_anoestrus and not gestating {
		if (not hormon_shot and cyclic) and (current_date = my_farmer.ram_introduction add_days day_of_first_heat) {
			first_heat <- true;
		}

		if (not hormon_shot and MER) and (current_date = my_farmer.ram_introduction add_days day_of_first_heat) {
			first_heat <- true;
		}

		if (hormon_shot and (current_date = my_farmer.retrait_eponge add_days day_of_first_heat_with_AI)) {
			first_heat <- flip(synchronization_rate);
		}

		if (not hormon_shot and not cyclic and not MER) or (hormon_shot and current_date between (my_farmer.retrait_eponge add_days 3, my_farmer.final_withdraw_date)) {
			latecomer <- true;
			state <- "in anoestrus";
		}

		if (first_heat) {
			in_heat <- true;
			in_anoestrus <- false;
			latecomer <- false;
			state <- "in heat";
			start_heating <- current_date;
			number_of_ewes_starting_heating <- number_of_ewes_starting_heating + 1;
		}

	}

	reflex end_of_heat_period when: in_heat and ((((current_date - start_heating) / #hour) mod 36) = 0) and (current_date > start_heating) {
		in_heat <- false;
	}

	reflex next_heats when: first_heat and not gestating and not in_heat and ((((current_date - start_heating)) mod (17 #day)) = 0) and (current_date > start_heating) {
		in_heat <- true;
		state <- "in heat";
		start_heating <- current_date;
		number_of_ewes_coming_back_into_heat <- number_of_ewes_coming_back_into_heat + 1;
	}

	reflex return_in_anoestrus when: current_date.month = 1 and current_date.day = 1 and current_date.hour = 0 {
		in_anoestrus <- true;
		in_heat <- false;
		first_heat <- false;
		cyclic <- false;
		MER <- false;
		latecomer <- false;
		state <- "in anoestrus";
	}

	reflex abortion_date_calcul when: gestating and current_date = start_gestation add_days 1 {
		abortion <- flip(proba_abortion);
		if (abortion) {
			abortion_date <- start_gestation add_days day_of_abortion;
		}

	}

	reflex abort when: gestating and abortion and current_date = abortion_date {
		if ((abortion_date - start_gestation) < 45 / #days) {
			gestating <- false;
		}

		if (abortion_date between (start_gestation add_days 45, start_gestation add_days (gestation_duration - 5))) {
			gestating <- false;
			first_heat <- false;
			in_heat <- false;
			in_anoestrus <- true;
			state <- "in anoestrus";
			nutrition_state <- "maintenance";
		}

	}

	reflex return_in_heat_after_abortion when: first_heat and not gestating and not in_heat and abortion and abortion_date != nil and ((current_date - abortion_date) = 15 / #days) {
		in_heat <- true;
		state <- "in heat";
		start_heating <- current_date;
		number_of_ewes_coming_back_into_heat <- number_of_ewes_coming_back_into_heat + 1;
	}

	reflex calcul_besUFL_gest when: not abortion and gestating and every(#day) {
		gestating_week <- int(((current_date - start_gestation) / #day) / 7);
		week_before_lambing <- (21 - gestating_week);
		if (week_before_lambing between (-1, 7)) {
			nutrition_state <- "gestating";
			besUFL_gest <- ((0.0896 * foetusweigth - (0.0145 * week_before_lambing * foetusweigth) - (0.0096 * week_before_lambing) + 0.0751)) * 0.956; 
			besPDI_gest <- ((-(1.28 * week_before_lambing * foetusweigth) + 12.6 * foetusweigth - (3.41 * week_before_lambing) + 17.6) * 0.58 / 0.58);
		} else {
			besUFL_gest <- 0.0;
			besPDI_gest <- 0.0;
		}

	}

	reflex lambing when: (gestating and (current_date = (start_gestation add_days gestation_duration))) { 
		gave_birth <- flip(easy_lambing);
		if (gave_birth) {
			lambing_count_day <- lambing_count_day + 1;
			gestating <- false;
			besUFL_gest <- 0.0; //because important energetic needs only in the last weeks, otherwise, negligible (INRAtion)
			besPDI_gest <- 0.0;
			lambing_date[current_date.year] <- current_date;
			in_heat <- false;
			first_heat <- false;
			suckling <- true;
			state <- "lactating";
			nutrition_state <- "suckling";
			start_milking[lact_num + 1] <- current_date add_days suckling_duration;
			number_of_ewes_lambing <- number_of_ewes_lambing + 1;
			total_lambing_count <- total_lambing_count + 1;
			to_portee <- flip(to_portee_2);
			if (to_portee) {
				lit_size <- 2;
			} else {
				to_portee3 <- flip(to_portee_3);
				if (to_portee3) {
					lit_size <- 3;
				}

			}

			if (flip(0.5)) {
				create ewe number: lit_size with: [age::-1] {
					my_farmer <- myself.my_farmer;
					my_farmer.my_ewes << self;
					birth_date <- current_date;
					BCS <- min(5.0, max(1.0, gauss(2.5, 0.3)));  
					days_since_lambing <- 0;
					newborn <- true;
					state <- "in anoestrus";
					nutrition_state <- "growing";
					weight <- 47.0;
				}

			} else {
				create ram number: lit_size with: [age::-1] {
					my_farmer <- myself.my_farmer;
					my_farmer.my_rams << self;
					birth_date <- current_date;
					newborn <- true;
					state <- "in anoestrus";
					nutrition_state <- "male";
				}

			}

		} else {
			culling <- true;
			gestating <- false;
			in_anoestrus <- true;
			state <- "in anoestrus";
			nutrition_state <- "maintenance";
		}

	}

	reflex calcul_of_suckling_needs when: every(#day) and nutrition_state = "suckling" {
		weight <- weight - 0.179;
		besUFL_suck <- (0.0035 * weight_gain_of_youngs_during_suck) + 0.0525; 
		besPDI_suck <- (0.37 * weight_gain_of_youngs_during_suck) + 7.5;
	}

	reflex start_of_lactation when: nutrition_state = "suckling" and current_date = last(start_milking) {
		suckling <- false;
		health_problem <- flip(proba_hp);
		if (not health_problem) {
			lactating <- true;
			state <- "lactating";
			nutrition_state <- "lactating";
			lact_num <- lact_num + 1;
			milk_prod[lact_num] <- [0];
			besUFL_suck <- 0.0;
			besPDI_suck <- 0.0;
			number_of_ewes_entering_milking <- number_of_ewes_entering_milking + 1;
		} else {
			lactating <- false;
			in_anoestrus <- true;
			state <- "in anoestrus";
			nutrition_state <- "maintenance";
			besUFL_suck <- 0.0;
			besPDI_suck <- 0.0;
		}

	}

	reflex milk_production when: lactating and nutrition_state = "lactating" and every(#day) {
		number_of_milking_days <- length(last(milk_prod.values)) + 1;
		if (lact_num > 1) {
			milk_prod[lact_num] <+ ewe_initial_milk_prod * exp(-(0.0028 + 0.0049 * ln(ewe_initial_milk_prod)) * (number_of_milking_days));
		} else {
			milk_prod[lact_num] <+ ewelamb_initial_milk_prod * exp(-(0.0021 + 0.0052 * ln(ewelamb_initial_milk_prod)) * (number_of_milking_days));
		}

		htmp_count_day <- htmp_count_day + last(milk_prod[lact_num]);
		number_of_milking_days <- length(last(milk_prod.values)) + 1;
		TB<-TB_inti_value + 0.122 * my_farmer.nbre_days_since_milking_start;
		TP<-TP_init_value+ 0.072 * my_farmer.nbre_days_since_milking_start;
		besUFL_MY <- 0.71 * last(milk_prod[lact_num]) * ((0.0071 * TB) + (0.0043 * TP) + 0.2224);
		besPDI_MY <- (last(milk_prod[lact_num]) * TP) / EffPDI;
		if (current_date between (last(start_milking), last(start_milking) add_days 91)) {
			weight <- weight - 0.022;
		}

		if (current_date between (last(start_milking) add_days 90, last(start_milking) add_days 151)) {
			BCSvariation <- 0.2; 
			weight <- weight + 0.033; 
			besUFL_maint <- (0.033 * (weight) ^ 0.75) + 0.43 * weight * (BCSvariation / 60); //60=2 months
			besPDI_maint <- (2.5 * (weight) ^ 0.75) + besUFL_maint * 33;
		}

		if (renew and age = 0 and lact_num = 1) and current_date between (last(start_milking) add_days 90, my_farmer.pose_eponge_ewelamb) {
			weight <- weight + 0.067; 
			besUFL_maint <- besUFL_maint + 0.28 * (67 / 100);
			besPDI_maint <- besPDI_maint + 0.130 * (67 / 0.58);
		}

	}

	reflex end_of_milking when: number_of_milking_days > 0 and nutrition_state = "lactating" and ((last(milk_prod[lact_num]) < prod_min) or (current_date = end_delivery_date)) {
		end_of_milking_date[lact_num] <- current_date;
		lactating <- false;
		number_of_milking_days <- 0;
		milk_prod[lact_num] <+ 0.0;
		besUFL_MY <- 0.0;
		besPDI_MY <- 0.0;
		state <- " in anoestrus";
		nutrition_state <- "maintenance";
		if (gestating) {
			state <- "gestating";
		}
	}

	reflex calcul_ctl {
		if (lactating and last(lambing_date) != nil and current_date = my_farmer.ctl_date[0]) {
			Ctl[0] <- ((last(milk_prod[lact_num])) * 1000); 
			Constante[0] <- ((my_farmer.ctl_date[0] - last(lambing_date)) / #day);
		}

		loop i from: 1 to: 4 {
			if (lactating and current_date = my_farmer.ctl_date[i]) {
				Ctl[i] <- ((last(milk_prod[lact_num])) * 1000);
				Constante[i] <- ((my_farmer.ctl_date[i] - my_farmer.ctl_date[i - 1]) / #day);
				
			}

		}

	}

	reflex reset_bool when: (current_date = my_farmer.ram_introduction) or (current_date = my_farmer.pose_eponge) {
		abortion <- false;
		gave_birth <- false;
	}
	
}

//////////////////////AGENT ELEVEUR/////////////////////
species farmer {

	rgb couleur <- #saddlebrown update: #saddlebrown;
	date ram_introduction;
	date ewe_lamb_start_mating_date;
	date second_ram_intro_date;
	date final_withdraw_date;
	date pose_eponge;
	date pose_eponge_ewelamb;
	date retrait_eponge;
	date retrait_eponge_ewelamb;
	date ewe_AI_date_with_hormone;
	date ewelamb_AI_date_with_hormone;
	date first_lambing_date;
	date last_lambing_date;
	date old_ewes_departure_date;
	date rst_month_of_lambing;
	date deb_management_period;
	list<list<date>> AI_dates;
	list<date> free_mating_dates;
	list<ram> my_rams;
	list<ewe> my_ewes;
	list<sheep> my_youngs;
	int number_of_culled_ewes;
	int nb_ewe_to_be_insem;
	int nbre_days_since_milking_start <- 0;
	float mean_gen_index;
	float flock_TB;
	float flock_TP;
	float bes_UFL_ewe;
	float bes_UFL_ewelamb;
	float bes_PDI_ewe;
	float bes_PDI_ewelamb;
	map<int, date> ctl_date;
	map<string, float> total_PDIE_intake;
	map<string, float> total_PDIN_intake;
	map<int, float> taille_troupeau;
	map<int, float> fertility_rate;
	map<int, float> grpt_1_month;
	svg_file icon <- svg_file("../includes/farmer.svg");
	string mating_period;
	bool ram_culling <- false;

	init {
		ram_introduction <- date(string(dates[2, 0]) split_with ",");
		pose_eponge <- date(string(dates[2, 2]) split_with ",");
		if ((ram_introduction.month between (2, 6)) or pose_eponge.month between (2, 6)) {
			mating_period <- "early";
		} else {
			mating_period <- "late";
		}
		write sample(mating_period);
		ewe_lamb_start_mating_date <- date(string(dates[2, 1]) split_with ",");
		second_ram_intro_date <- date(string(dates[2, 9]) split_with ",");
		pose_eponge_ewelamb <- date(string(dates[2, 11]) split_with ",");
		retrait_eponge <- pose_eponge add_days 14;
		retrait_eponge_ewelamb <- pose_eponge_ewelamb add_days 14;
		ewe_AI_date_with_hormone <- retrait_eponge add_days 2;
		ewelamb_AI_date_with_hormone <- retrait_eponge_ewelamb add_days 2;
		final_withdraw_date <- date(string(dates[2, 10]) split_with ",");
		end_delivery_date <- date(string(dates[2, 3]) split_with ",");
		old_ewes_departure_date <- end_delivery_date add_days 1;
		loop i from: 0 to: number_of_milk_monitoring {
			ctl_date[i] <- date(string(dates[2, i + 4]) split_with ","); 
		}

	}
	reflex essai_dates when: current_date = starting_date {
		AI_dates <- calcul_insemination_dates();
		free_mating_dates <- calcul_freemating_dates();
	}
	
	
	reflex esszi when: current_date=flock_milking_start{
		write sample(flock_milking_start);
	}

	reflex choice_of_dates when: (current_date = ram_introduction add_months 11) or (current_date = pose_eponge add_months 11) {
		ram_introduction <- ram_introduction add_years 1;
		pose_eponge <- pose_eponge add_years 1;
		ask (ewe where (not empty(each.lambing_date))) {
			days_since_lambing <- int((my_farmer.ram_introduction - last(lambing_date)) / #day);
			if (days_since_lambing < 0) {
				days_since_lambing <- 0;
			}

			days_since_lambing <- int((my_farmer.ram_introduction - last(lambing_date)) / #day);

		}

		ewe_lamb_start_mating_date <- ewe_lamb_start_mating_date add_years 1;
		second_ram_intro_date <- second_ram_intro_date add_years 1;
		pose_eponge_ewelamb <- pose_eponge_ewelamb add_years 1;
		retrait_eponge <- pose_eponge add_days 14;
		retrait_eponge_ewelamb <- pose_eponge_ewelamb add_days 14;
		ewe_AI_date_with_hormone <- retrait_eponge add_days 2;
		ewelamb_AI_date_with_hormone <- retrait_eponge_ewelamb add_days 2;
		AI_dates <- calcul_insemination_dates();
		free_mating_dates <- calcul_freemating_dates();
		final_withdraw_date <- final_withdraw_date add_years 1;
	}

	reflex choix_periode_lutte when: current_date = ram_introduction or current_date = pose_eponge {
		number_of_culled_ewes <- int(flock_size * turnover_rate);
		loop i from: 0 to: number_of_milk_monitoring {
			ctl_date[i] <- ctl_date[i] add_years 1;
		}

	}

	reflex calcul_nbre_milking_days when: every(#day) {
		
		if (current_date between (flock_milking_start minus_days 1, end_delivery_date add_days 1)) {
			nbre_days_since_milking_start <- int((current_date - flock_milking_start) / #day) + 1;
			//write current_date+ sample(int((current_date - flock_milking_start) / #day))+ sample(nbre_milking_days);
			flock_TB <- mean(ewe where (each.nutrition_state = "lactating") collect (each.TB));
			flock_TP <- mean(ewe where (each.nutrition_state = "lactating") collect (each.TP));
		} else {
			nbre_days_since_milking_start <- 0;
			flock_TB <- 0.0;
			flock_TP <- 0.0;
		}

	}

	list<list<date>> calcul_insemination_dates {
		if(scenario="scenar3" or scenario="scenar"){
		return [[ram_introduction add_days 18, ram_introduction add_days 20], [ram_introduction add_days 24, ram_introduction add_days 26]];}
		if(scenario="scenar1"or scenario="scenar5"){
		return [[ram_introduction add_days 17, ram_introduction add_days 22]];}
		
	}

	list<date> calcul_freemating_dates {
		if (not hormon_shot and AI) {
			return [last(last(AI_dates)) add_days 6, last(last(AI_dates)) add_days ewesonly_free_mating_duration];
		}

		if (not hormon_shot and not AI) {
			return [ram_introduction add_days male_effect_duration, (ram_introduction add_days male_effect_duration) add_days ewesonly_free_mating_duration];
		}

		if (hormon_shot and AI) {
			return [ewe_AI_date_with_hormone add_days 15, ewe_AI_date_with_hormone add_days (15 + ewesonly_free_mating_duration)];
		} 
	
	}

	aspect default {
		draw icon size: {0.75, 2} color: couleur rotate: 180;
		draw ("Date: " + current_date.day + "/" + current_date.month + "/" + current_date.year) font: font("SansSerif", 24, #bold) at: location + {10, 0} color: #white;
	}

	
	reflex choose_ewe_to_inseminate when: AI and ((current_date = pose_eponge) or (current_date = ram_introduction)) {
		if (hormon_shot) {
			nb_ewe_to_be_insem <- int(AI_rate * length(ewe where ((each.age >= 1))));
			list<ewe> ewes_to_be_insem <- ewe where (each.age >= 1 and not each.culling_for_age and not each.culling_for_perf);
			ask (nb_ewe_to_be_insem among ewes_to_be_insem) {
			
				to_be_inseminate <- true;
			}

			list<ewe> ewe_lambs <- ewe where (each.renew and each.age < 1);
			ask ((youngs_AI_rate * length(ewe_lambs)) among ewe_lambs) {
				to_be_inseminate <- true;
			}

		} else {
			ask (ewe) {
				to_be_inseminate <- true;
			}

		}

	}

	reflex inseminates_without_hormones when: AI and not hormon_shot and not empty(AI_dates where (current_date between (each[0], each[1]))) {
		list<ewe> ewes_that_could_be_gest <- ewe where (each.to_be_inseminate and each.in_heat); 
		
		ask (int(detection_rate*length(ewes_that_could_be_gest))among ewes_that_could_be_gest){
				gestating <- flip(proba_AI_sucess);
			to_be_inseminate <- false;
			if (gestating) {
				gestating <- true;
				in_heat <- false;
				state <- "gestating";
				nutrition_state <- "maintenance"; 
				couleur <- #orange;
				start_gestation <- current_date;
				number_of_gestating_females <- number_of_gestating_females + 1;
			}

		}

	}

	reflex inseminates_ewes_with_hormone when: AI and hormon_shot and (current_date = ewe_AI_date_with_hormone) {
		list<ewe> ewes_candidates <- ewe where (each.age >= 1 and (each.to_be_inseminate) and (each.in_heat)); 
		ask (ewes_candidates) {
			gestating <- flip(proba_AI_sucess);
			to_be_inseminate <- false;
			if (gestating) {
				gestating <- true;
				in_heat <- false;
				state <- "gestating";
				nutrition_state <- "maintenance";
				couleur <- #orange;
				start_gestation <- current_date;
				number_of_gestating_females <- number_of_gestating_females + 1;
			}

		}

	}

	reflex inseminates_youngs_with_hormone when: AI and hormon_shot and (current_date = ewelamb_AI_date_with_hormone) {
	
		list<ewe> ewelambs_candidates <- ewe where (each.renew and each.to_be_inseminate and each.in_heat);  
		
		ask (ewelambs_candidates) {
			gestating <- flip(young_proba_AI_sucess);
			to_be_inseminate <- false;
			if (gestating) {
				gestating <- true;
				in_heat <- false;
				state <- "gestating";
				nutrition_state <- "maintenance";
				couleur <- #orange;
				start_gestation <- current_date;
				number_of_gestating_females <- number_of_gestating_females + 1;
			}

		}

	}

	reflex introduction_of_freemating_ram when: current_date between (first(free_mating_dates), last(free_mating_dates)) {
		ask (ram where (each.age > 1)) {
			active <- true;
			state <- "active";
		}

	}

	reflex withdrawal_of_freemating_ram when: (current_date = last(free_mating_dates)) {
		ask (ram where (each.age > 1)) {
			active <- false;
			state <- "resting";
		}

	}

	reflex introduction_of_freemating_ram_for_ewelambs when: current_date between (ewe_lamb_start_mating_date, final_withdraw_date) {
		ask (ram where (each.age > 1)) {
			active_for_ewelambs <- true;
			state <- "active";
		}

	}

	reflex second_introduction_of_freemating_ram when: current_date between (second_ram_intro_date, final_withdraw_date) {
		ask (ram where (each.age > 1)) {
			active <- true;
			state <- "active";
		}

	}

	reflex final_withdrawal_of_freemating_ram when: (current_date = final_withdraw_date) {
		ask (ram where (each.age > 1)) {
			active <- false;
			active_for_ewelambs <- false;
			state <- "resting";
		}

	}

	reflex chosing_end_of_delivery_date when: current_date > end_delivery_date {
		old_ewes_departure_date <- end_delivery_date add_days 1;
		flock_milking_start <- flock_milking_start add_years 1;
		end_delivery_date <- end_delivery_date add_years 1;
	}

	reflex choice_of_old_ewes_for_culling when: (not hormon_shot and current_date = ram_introduction add_months 10) or (hormon_shot and current_date = pose_eponge add_months 10) {
		list<ewe> old_ewes_to_be_culled <- (ewe where (each.age >= culling_age)) sort_by (-1 * each.age); 
		ask (number_of_culled_ewes first (old_ewes_to_be_culled)) {
			culling_for_age <- true;

			
		}

	}

	reflex choice_of_ewes_to_cull_for_performances when: (not hormon_shot and current_date = ram_introduction add_months 10) or (hormon_shot and current_date = pose_eponge
	add_months 10) {
		list<ewe> old_ewes_to_be_culled2 <- ewe where ((each.milk_prod contains_key each.lact_num) and (sum(each.milk_prod[each.lact_num]) > 0)) sort_by
		(sum(each.milk_prod[each.lact_num]));
		
		ask ((number_of_culled_ewes - length(ewe where (each.culling_for_age))) first (old_ewes_to_be_culled2)) {
			culling_for_perf <- true;
		}

	}

	reflex choice_of_old_rams_for_culling when: (not hormon_shot and current_date = ram_introduction add_months 10) or (hormon_shot and current_date = pose_eponge add_months 10) {
		list<ram> old_rams_to_be_culled <- (ram where (each.age >= 4)) sort_by (-1 * each.age); 
		
		list<ram> adultrams <- ram where (each.age >= 1);
		
		if ((length(adultrams) >= (length(ewe where (each.age > 1)) / 23))) {
			ask (int(length(adultrams) - (length(ewe where (each.age > 1)) / 23)) among old_rams_to_be_culled) {
				culling_for_age <- true; 
				my_farmer.ram_culling <- true;
			}

		}

	}

	reflex culling_of_old_ewes_and_rams when: current_date = old_ewes_departure_date {

		ask (ewe where each.culling_for_age) {
			nb_culled_ad <- nb_culled_ad + 1;
			nb_culled_ad_tot <- nb_culled_ad_tot + 1;
			my_farmer.my_ewes >> self;
			do die;
		}

		ask (ewe where each.culling_for_perf) {
			nb_culled_ad <- nb_culled_ad + 1;
			my_farmer.my_ewes >> self;
			do die;
		}

		write sample(ram count each.culling_for_age);
		ask (ram where each.culling_for_age) {
			nb_culled_ad_tot <- nb_culled_ad_tot + 1;
			my_farmer.my_rams >> self;
			do die;
		}

	}

	reflex involuntary_culling when: (current_date = ram_introduction add_months 10) or (current_date = pose_eponge add_months 10) {
		list<ewe> ewes_to_be_culled_accidentally <- (ewe where (each.culling)); 
		
		ask (ewes_to_be_culled_accidentally) {
			my_farmer.my_ewes >> self;
			do die;
		}

	}

	reflex mortality_and_choice_of_lambs_for_renewal when: ((current_date = ram_introduction add_months 10) or (current_date = pose_eponge add_months 10)) {
		my_youngs <- ewe where (each.newborn) + ram where (each.newborn);
		ask ((length(my_youngs) * mortality_rate) among my_youngs) {
			my_farmer.my_youngs >> self;
			my_farmer.my_ewes >> self;
			do die;
		}

		list<ewe> ewelambs_by_birth_date <- ewe where (each.newborn) sort_by (each.birth_date);
		
		young_ewes_sales <- length(ewelambs_by_birth_date) - (number_of_culled_ewes);
		sales_youngs <- sales_youngs + length(young_ewes_sales last (ewelambs_by_birth_date));
		ask (young_ewes_sales last (ewelambs_by_birth_date)) { 
			my_farmer.my_youngs >> self;
			my_farmer.my_ewes >> self;
			do die;
		}

		if (ram_culling) {
			young_ram_sales <- length(ram where (each.newborn)) - length(ram where each.culling_for_age);
			ram_culling <- false;
			sales_youngs <- sales_youngs + young_ram_sales;
		} else {
			young_ram_sales <- length(ram where (each.newborn));
			sales_youngs <- sales_youngs + young_ram_sales;
		}

		ask (young_ram_sales among (ram where (each.newborn))) {
			my_farmer.my_youngs >> self;
			my_farmer.my_rams >> self;
			do die;
		}

		
		flock_size <- length(ewe) - length(ewe where each.culling_for_age) - length(ewe where each.culling_for_perf); 
		write "flock_size(one month from mating)" + flock_size;
	}

	reflex calcul_lambing_period when: (current_date = ram_introduction add_months 10) or (current_date = pose_eponge add_months 10) {
		list<ewe> ewes_per_lambing_dates <- (ewe where (each.gave_birth)) sort_by ((last(each.lambing_date)));
		ask first(ewes_per_lambing_dates) {
			myself.first_lambing_date <- last(self.lambing_date);
			myself.rst_month_of_lambing <- myself.first_lambing_date add_months 1;
			write sample(myself.rst_month_of_lambing);
		}

		ask last(ewes_per_lambing_dates) {
			myself.last_lambing_date <- last(self.lambing_date);
		}

		fertility_rate[milk_prod_campaign_number] <- length(ewes_per_lambing_dates) / last(taille_troupeau[milk_prod_campaign_number]);
		write "Fertility rate:" + fertility_rate[milk_prod_campaign_number];
		write "First lambing:" + (first(ewes_per_lambing_dates)) + ":" + first_lambing_date;
		write "Last lambing:" + (last(ewes_per_lambing_dates)) + ":" + last_lambing_date;
		write "Lambing period (days):" + ((last_lambing_date - first_lambing_date) / #days);
		list<ewe> ewes_that_lambed_in_1_month <- ewes_per_lambing_dates where (last(each.lambing_date) <= rst_month_of_lambing);
		grpt_1_month[milk_prod_campaign_number] <- length(ewes_that_lambed_in_1_month) / length(ewe where each.gave_birth);
		write sample(grpt_1_month[milk_prod_campaign_number]);
	}

	reflex calcul_TMP_of_the_herd when: current_date = end_delivery_date {
		list<ewe> ewe_that_producted <- ewe where ((each.milk_prod contains_key each.lact_num) and (sum(each.milk_prod[each.lact_num]) > 0));
		htmp[milk_prod_campaign_number] <- (ewe_that_producted sum_of (sum(each.milk_prod[each.lact_num])));
		write "Total_milk_prod of herd (L):" + htmp[milk_prod_campaign_number];
		write "TMP mean (L/ewe):" + (ewe_that_producted mean_of (sum(each.milk_prod[each.lact_num])));
		milk_prod_campaign_number <- milk_prod_campaign_number + 1;
		taille_troupeau[milk_prod_campaign_number] <- flock_size;
		write "check taille de troupeau de la campagne:" + last(taille_troupeau[milk_prod_campaign_number]);
		
	}

	reflex calcul_besoins_nrj_prot when: every(#day) {
		nb_dry_or_maintening_ewes[current_date] <- length((ewe where (each.lact_num > 0 and not each.gestating and not each.lactating and each.nutrition_state != "suckling")));
		nb_dry_or_maintening_ewelambs[current_date] <- length(ewe where (each.renew and each.lact_num = 0 and not each.gestating and not each.lactating and each.nutrition_state !=
		"suckling"));
		nb_gestating_ewes[current_date] <- length(ewe where (each.lact_num > 0 and each.nutrition_state = "gestating"));
		nb_gestating_ewelambs[current_date] <- length(ewe where (each.renew and each.lact_num = 0 and each.nutrition_state = "gestating"));
		nb_suckling_ewes[current_date] <- length(ewe where (each.lact_num > 0 and each.nutrition_state = "suckling"));
		nb_suckling_ewelambs[current_date] <- length(ewe where (each.gave_birth and each.renew and each.lact_num = 0 and each.nutrition_state = "suckling"));
		nb_lactating_ewes[current_date] <- length(ewe where (each.lact_num > 0 and each.nutrition_state = "lactating"));
		nb_lactating_ewelambs[current_date] <- length(ewe where (each.gave_birth and each.renew and each.lact_num = 0 and each.nutrition_state = "lactating"));

		//////energy needs/////
		bes_UFL_ewe <- sum((ewe where (each.lact_num > 0)) collect (each.bes_UFL_tot));
		
		bes_UFL_ewelamb <- sum((ewe where (each.renew and each.lact_num = 0)) collect (each.bes_UFL_tot));
		
		flock_bes_UFL[current_date] <- sum(ewe collect (each.bes_UFL_tot));

		////prot needs///
		bes_PDI_ewe <- sum((ewe where (each.lact_num > 0)) collect (each.bes_PDI_tot));
		
		bes_PDI_ewelamb <- sum((ewe where (each.renew and each.lact_num = 0)) collect (each.bes_PDI_tot));
		
		flock_bes_PDI[current_date] <- sum(ewe collect (each.bes_PDI_tot));
	}

}




experiment experiment1 type: gui {
//float minimum_cycle_duration <- 0.03;
/** Insert here the definition of the input and output of the model */
	output {
		display Farm {
			overlay position: {5, 5} size: {180 #px, 240 #px} background: #black transparency: 0.5 border: #black rounded: true {
			//for each possible type, we draw a square with the corresponding color and we write the name of the type
				float y <- 30 #px;
				draw "Ewes" at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
				y <- y + 30 #px;
				loop type over: ewes_state_color.keys {
					draw square(10 #px) at: {20 #px, y} color: ewes_state_color[type] border: #white;
					draw type at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
					y <- y + 25 #px;
				}

				draw line([{10 #px, y}, {170 #px, y}]) color: #white;
				y <- y + 20 #px;
				draw "Rams" at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
				y <- y + 30 #px;
				loop type over: rams_state_color.keys {
					draw square(10 #px) at: {20 #px, y} color: rams_state_color[type] border: #white;
					draw type at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
					y <- y + 25 #px;
				}

			}

			graphics "background" {
				draw background_breeder color: #lightgray border: #black;
				draw background_ewes color: #lightgreen border: #black;
				draw background_rams color: #lightblue border: #black;
			}

			species ewe;
			species ram;
			species farmer;
			
		}

		display Flock_size refresh: every(1 #day) {
			chart "Evolution of herd size" size: {1.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Herd size' {
				data "number of ewes" value: length(ewe) color: #red;
				data "number of rams" value: length(ram) color: #blue;
			}

			chart "Age repartition in the herd" size: {1.0, 0.5} position: {0.0, 0.5} type: histogram y_label: 'Herd size' {
				data "[0,1[" value: (ewe count (each.age < 1)) color: #red;
				data "[1,2[" value: (ewe count ((each.age >= 1) and (each.age < 2))) color: #red;
				data "[2,3[" value: (ewe count ((each.age >= 2) and (each.age < 3))) color: rgb(255, 0, 0);
				data "[3,4[" value: (ewe count ((each.age >= 3) and (each.age < 4))) color: #red;
				data "[4,5[" value: (ewe count ((each.age >= 4) and (each.age < 5))) color: #red;
				data "[5,6[" value: (ewe count ((each.age >= 5) and (each.age < 6))) color: #red;
				data "[6,7[" value: (ewe count ((each.age >= 6) and (each.age < 7))) color: #red;
				data "[7,8[" value: (ewe count ((each.age >= 7) and (each.age < 8))) color: #red;
				data "[8,9[" value: (ewe count ((each.age >= 8) and (each.age < 9))) color: #red;
				data "[9, inf[" value: (ewe count ((each.age >= 9))) color: #red;
			}

		}

		display Daily_stages_follow_up refresh: every(1 #days) {
			chart "Evolution of states in the herd" size: {1.0, 0.5} x_label: 'Time (1/2 day)' {
				data "number of ewes starting heating" value: number_of_ewes_starting_heating color: #green;
				data "number of ewes-lamb starting heating" value: number_of_ewelamb_starting_heating color: #darkblue;
				data "total heats" value: ewe count (each.in_heat) color: #pink;
				data "number of ewes coming back into heat" value: number_of_ewes_coming_back_into_heat color: #lime;
				data "number of gestating ewes" value: number_of_gestating_females color: #mediumvioletred;
				data "number of ewes lambing" value: number_of_ewes_lambing color: #gamaorange;
				data "number of ewes entering milking" value: number_of_ewes_entering_milking color: #blue;
			}

			chart "Zoom" size: {1.0, 0.5} position: {0.0, 0.5} x_range: 100 x_label: 'Time (1/2 day)' {
				data "number of ewes starting heating" value: number_of_ewes_starting_heating style: bar color: #green;
				data "number of ewes-lamb starting heating" value: number_of_ewelamb_starting_heating style: bar color: #darkblue;
				data "total heats" value: ewe count (each.in_heat) style: bar color: #pink;
				data "number of ewes coming back into heat" value: number_of_ewes_coming_back_into_heat style: bar color: #lime;
				data "number of gestating ewes" value: number_of_gestating_females style: bar color: #mediumvioletred;
				data "number of ewes lambing" value: number_of_ewes_lambing style: bar color: #gamaorange;
				data "number of ewes entering milking" value: number_of_ewes_entering_milking style: bar color: #blue;
			}

		}

		display Milk_production_of_the_flock refresh: every(1 #day) {
			chart "Total milk production of the herd/day" size: {1.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Cumulative milk production (L)' {
				data "Total milk production of the herd/day" value: sum((ewe where each.lactating) collect (last(each.milk_prod[each.lact_num]))) color: #blue;
			}

			chart "Average milk production per milking ewe per day" size: {1.0, 0.5} position: {0.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Average milk production (L)' {
				data "Average milk production/milking ewe/day" value: mean((ewe where each.lactating) collect (last(each.milk_prod[each.lact_num]))) style: line color: #green;
			}

		}

		

		display Batch_sizes refresh: every(#day) {
			chart "Effectives of ewes in different physiologique states " size: {1.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Batch size' {
				data "nb ewes in maintenance" value: last(nb_dry_or_maintening_ewes) style: bar color: #lightgreen;
				data "nb ewes gestating" value: last(nb_gestating_ewes) style: bar color: #orange;
				data "nb ewes suckling" value: last(nb_suckling_ewes) style: bar color: #lightblue;
				data "nb ewes lactating" value: last(nb_lactating_ewes) style: bar color: #pink;
			}

			chart "Effectives of ewelambs in different physiologique states " size: {1.0, 0.5} position: {0.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Batch size' {
				data "nb ewelambs in maintenance" value: last(nb_dry_or_maintening_ewelambs) style: bar color: #green;
				data "nb ewelambs gestating" value: last(nb_gestating_ewelambs) style: bar color: #maroon;
				data "nb ewelambs suckling" value: last(nb_suckling_ewelambs) style: bar color: #blue;
				data "nb ewelambs lactating" value: last(nb_lactating_ewelambs) style: bar color: #purple;
			}

		}


		

		display Nutritional_needs refresh: every(#week) {
			chart "Mean need in UFL/j  " size: {1.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Mean need in UFL/j' {
				data "Mean need in UFL/j reproductive females" value: last(flock_bes_UFL) color: #purple;
				
			}

			chart "Mean need in PDI (g/j) " size: {1.0, 0.5} position: {0.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Mean need in PDI g/j' {
				data "Mean need in PDI g/j reproductive females" value: last(flock_bes_PDI) color: #purple;
				
			}

		}

	}

}



experiment 'Exploration scenarios' type: gui { 
	action _init_ {
		
		save "Simulation name,scenario,  total lambing count" to: "Scenar_outputs/Results_tlc_campagne.txt";
		save "Simulation name,scenario,  lambing per day" to: "Scenar_outputs/Results_LC_day.txt";
		save "Simulation name,scenario,  herd milk prod " to: "Scenar_outputs/Results_HTMP_campagne.txt";
		save "Simulation name,scenario,  herd milk per day " to: "Scenar_outputs/Results_HTMP_day_campagne.txt";
		save "Simulation name,scenario, date,nb ewes maint, nb ewes gest, nb ewes suck, nb ewes lact" to:
		"Scenar_outputs/Results_phys_stage_ewes.txt";
		save "Simulation name,scenario, date, PDI_needs,  UFL_needs" to: "Scenar_outputs/Results_nutritional_requirements.txt" rewrite: false type: text;
		csv_file parameter_values_csv_file <- csv_file("../includes/Plan_scenar.csv");
		matrix data_explore <- matrix(parameter_values_csv_file);
		loop i from: 0 to: data_explore.rows - 1 {
			loop times: 1 {
				create simulation with:
				[scenario::string(data_explore[0, i]), seed::rnd(1.0), starting_date::date(string(data_explore[1, i])split_with ","), data2::csv_file("../includes/inputs/Management_dates_scenar"+i+".csv", ";", true), flock_milking_start::date(string(data_explore[2, i])split_with ",")];
			}

		}

	}

}

