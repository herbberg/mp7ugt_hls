-- Description:
-- Global Trigger Logic module.

-- Version-history:
-- HB 2018-08-23: version for use with HLS generated code. Inserted instance of IP core from HLS.
-- HB 2018-08-06: v1.6.0: Added ports and pipelines for "Asymmetry" (asymet_data, ...) and "Centrality" (centrality_data).
-- HB 2017-10-06: v1.5.0: Used new modules for use of std_logic_vector for limits of correlation cuts 
-- HB 2017-09-15: v1.4.1: Bug fix in calo_calo_correlation_condition_v3.vhd
-- HB 2017-09-08: v1.4.0: Updated modules for correct use of object slices
-- HB 2017-07-03: v1.3.3: Charge correlation comparison inserted for different bx data (bug fix) in muon_muon_correlation_condition_v2.vhd
-- HB 2017-06-26: v1.3.2: Changed port order for muon_conditions_v5.vhd and updated gtl_pkg_tpl.vhd (and gtl_pkg_sim.vhd) for muon-esums precisions
-- HB 2017-05-15: v1.3.1: Used calo_calo_calo_correlation_orm_condition.vhd instead of calo_1plus1_orm_condition.vhd and calo_2plus1_orm_condition.vhd
-- HB 2017-04-07: v1.3.0: Prepared for using ORM conditions (calo_conditions_orm.vhd, calo_1plus1_orm_condition.vhd and calo_2plus1_orm_condition.vhd)
-- HB 2017-04-05: v1.2.1: Created new VHDL module: twobody_pt_calculator
-- HB 2016-09-16: v1.2.0: 
-- 	Implemented "slices" for object range in all condition types.
-- 	Created new VHDL modules: mass_cuts, dr_calculator_v2, calo_conditions_v4, muon_conditions_v4,
--		calo_calo_correlation_condition_v2, calo_esums_correlation_condition_v2, calo_muon_correlation_condition_v2
--		muon_muon_correlation_condition_v2, muon_esums_correlation_condition_v2, calo_muon_muon_b_tagging_condition
-- HB 2016-09-16: v1.1.0: Implemented new esums with ETTEM, "TOWERCNT" (ECAL sum), ETMHF and HTMHF.
-- HB 2016-08-31: v1.0.0: Same version as v0.0.10
-- HB 2016-04-22: v0.0.10: Implemented min_bias_hf_conditions.vhd for minimum bias trigger conditions for low-pileup-run in May 2016.
--                         Updated gtl_fdl_wrapper.vhd and p_m_2_bx_pipeline.vhd for minimum bias trigger objects.
-- HB 2016-04-07: v0.0.9: Cleaned-up typing in muon_muon_correlation_condition.vhd (D_S_I_MUON_V2 instead of D_S_I_MUON in some lines).

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.gtl_pkg.all;

entity gtl_module is
    port(
        lhc_clk : in std_logic;
        eg_data : in calo_objects_array(0 to NR_EG_OBJECTS-1);
        jet_data : in calo_objects_array(0 to NR_JET_OBJECTS-1);
        tau_data : in calo_objects_array(0 to NR_TAU_OBJECTS-1);
        ett_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        ht_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        etm_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        htm_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- ****************************************************************************************
-- HB 2016-04-18: updates for "min bias trigger" objects (quantities) for Low-pileup-run May 2016
        mbt1hfp_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        mbt1hfm_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        mbt0hfp_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        mbt0hfm_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- HB 2016-06-07: inserted new esums quantities (ETTEM and ETMHF).
        ettem_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        etmhf_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- HB 2016-09-16: inserted HTMHF and TOWERCNT
        htmhf_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        towercount_data : in std_logic_vector(MAX_TOWERCOUNT_BITS-1 downto 0);
-- HB 2018-08-06: inserted signals for "Asymmetry" and "Centrality" (included in esums data structure).
        asymet_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        asymht_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        asymethf_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        asymhthf_data : in std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
        centrality_data : in std_logic_vector(NR_CENTRALITY_BITS-1 downto 0);
-- ****************************************************************************************
        muon_data : in muon_objects_array(0 to NR_MUON_OBJECTS-1);
        external_conditions : in std_logic_vector(NR_EXTERNAL_CONDITIONS-1 downto 0);
        algo_o : out std_logic_vector(NR_ALGOS-1 downto 0));
end gtl_module;

architecture rtl of gtl_module is
    constant external_conditions_pipeline_stages: natural := 2; -- pipeline stages for "External conditions" to get same pipeline to algos as conditions
    constant centrality_bits_pipeline_stages: natural := 2; -- pipeline stages for "Centrality" to get same pipeline to algos as conditions

-- HB 2016-03-08: "workaraound" for VHDL-Producer output
    constant NR_MU_OBJECTS: positive := NR_MUON_OBJECTS;

    signal mu_bx_p2, mu_bx_p1, mu_bx_0, mu_bx_m1, mu_bx_m2 : muon_objects_array(0 to NR_MUON_OBJECTS-1);
    signal eg_bx_p2, eg_bx_p1, eg_bx_0, eg_bx_m1, eg_bx_m2 : calo_objects_array(0 to NR_EG_OBJECTS-1);
    signal jet_bx_p2, jet_bx_p1, jet_bx_0, jet_bx_m1, jet_bx_m2 : calo_objects_array(0 to NR_JET_OBJECTS-1);
    signal tau_bx_p2, tau_bx_p1, tau_bx_0, tau_bx_m1, tau_bx_m2 : calo_objects_array(0 to NR_TAU_OBJECTS-1);
    signal ett_bx_p2, ett_bx_p1, ett_bx_0, ett_bx_m1, ett_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- HB 2015-04-28: changed for "htt" - object type from TME [string(1 to 3)] in esums_conditions.vhd
    signal htt_bx_p2, htt_bx_p1, htt_bx_0, htt_bx_m1, htt_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal etm_bx_p2, etm_bx_p1, etm_bx_0, etm_bx_m1, etm_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal htm_bx_p2, htm_bx_p1, htm_bx_0, htm_bx_m1, htm_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- ****************************************************************************************
-- HB 2016-04-18: updates for "min bias trigger" objects (quantities) for Low-pileup-run May 2016
    signal mbt1hfp_bx_p2, mbt1hfp_bx_p1, mbt1hfp_bx_0, mbt1hfp_bx_m1, mbt1hfp_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal mbt1hfm_bx_p2, mbt1hfm_bx_p1, mbt1hfm_bx_0, mbt1hfm_bx_m1, mbt1hfm_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal mbt0hfp_bx_p2, mbt0hfp_bx_p1, mbt0hfp_bx_0, mbt0hfp_bx_m1, mbt0hfp_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal mbt0hfm_bx_p2, mbt0hfm_bx_p1, mbt0hfm_bx_0, mbt0hfm_bx_m1, mbt0hfm_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- HB 2016-06-07: inserted new esums quantities (ETTEM and ETMHF).
    signal ettem_bx_p2, ettem_bx_p1, ettem_bx_0, ettem_bx_m1, ettem_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal etmhf_bx_p2, etmhf_bx_p1, etmhf_bx_0, etmhf_bx_m1, etmhf_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
-- HB 2016-09-16: inserted HTMHF and TOWERCNT
    signal htmhf_bx_p2, htmhf_bx_p1, htmhf_bx_0, htmhf_bx_m1, htmhf_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal towercount_bx_p2, towercount_bx_p1, towercount_bx_0, towercount_bx_m1, towercount_bx_m2 : std_logic_vector(MAX_TOWERCOUNT_BITS-1 downto 0);
-- HB 2018-08-06: inserted "Asymmetry" and "Centrality"
    signal asymet_bx_p2, asymet_bx_p1, asymet_bx_0, asymet_bx_m1, asymet_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal asymht_bx_p2, asymht_bx_p1, asymht_bx_0, asymht_bx_m1, asymht_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal asymethf_bx_p2, asymethf_bx_p1, asymethf_bx_0, asymethf_bx_m1, asymethf_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal asymhthf_bx_p2, asymhthf_bx_p1, asymhthf_bx_0, asymhthf_bx_m1, asymhthf_bx_m2 : std_logic_vector(MAX_ESUMS_BITS-1 downto 0);
    signal centrality_bx_p2_int, centrality_bx_p1_int, centrality_bx_0_int, centrality_bx_m1_int, centrality_bx_m2_int : std_logic_vector(NR_CENTRALITY_BITS-1 downto 0);
    signal centrality_bx_p2, centrality_bx_p1, centrality_bx_0, centrality_bx_m1, centrality_bx_m2 : std_logic_vector(NR_CENTRALITY_BITS-1 downto 0);
-- ****************************************************************************************
-- HB 2016-01-08: renamed ext_cond after +/-2bx to ext_cond_bx_p2_int, etc., because ext_cond_bx_p2, etc. used in algos (names coming from TME grammar).
    signal ext_cond_bx_p2_int, ext_cond_bx_p1_int, ext_cond_bx_0_int, ext_cond_bx_m1_int, ext_cond_bx_m2_int : std_logic_vector(NR_EXTERNAL_CONDITIONS-1 downto 0);
    signal ext_cond_bx_p2, ext_cond_bx_p1, ext_cond_bx_0, ext_cond_bx_m1, ext_cond_bx_m2 : std_logic_vector(NR_EXTERNAL_CONDITIONS-1 downto 0);

--    signal algo, algo_int, algo_int_1, algo_int_2 : std_logic_vector(NR_ALGOS-1 downto 0) := (others => '0');
    signal a_i_1, algo_int_1, algo_int_2 : std_logic_vector(MAX_NR_ALGOS-1 downto 0) := (others => '0');
    type a_i_array is array (natural range <>) of std_logic_vector(0 downto 0);
    signal a_i : a_i_array(MAX_NR_ALGOS-1 downto 0) := (others => "0");

-- 2018-08-21: signals for IP "algo_0" from hls4gtl
--     signal ap_rst : std_logic := '0'; -- always '0' for "not reseted"
    signal ap_start : std_logic := '1'; -- always '1' for "started"
    signal ap_done, ap_idle, ap_ready : std_logic;

begin

p_m_2_bx_pipeline_i: entity work.p_m_2_bx_pipeline
    port map(
        lhc_clk,
        muon_data, mu_bx_p2, mu_bx_p1, mu_bx_0, mu_bx_m1, mu_bx_m2,
        eg_data, eg_bx_p2, eg_bx_p1, eg_bx_0, eg_bx_m1, eg_bx_m2,
        jet_data, jet_bx_p2, jet_bx_p1, jet_bx_0, jet_bx_m1, jet_bx_m2,
        tau_data, tau_bx_p2, tau_bx_p1, tau_bx_0, tau_bx_m1, tau_bx_m2,
        ett_data, ett_bx_p2, ett_bx_p1, ett_bx_0, ett_bx_m1, ett_bx_m2,
        ht_data, htt_bx_p2, htt_bx_p1, htt_bx_0, htt_bx_m1, htt_bx_m2,
        etm_data, etm_bx_p2, etm_bx_p1, etm_bx_0, etm_bx_m1, etm_bx_m2,
        htm_data, htm_bx_p2, htm_bx_p1, htm_bx_0, htm_bx_m1, htm_bx_m2,
-- ****************************************************************************************
-- HB 2016-04-18: updates for "min bias trigger" objects (quantities) for Low-pileup-run May 2016
        mbt1hfp_data, mbt1hfp_bx_p2, mbt1hfp_bx_p1, mbt1hfp_bx_0, mbt1hfp_bx_m1, mbt1hfp_bx_m2,
        mbt1hfm_data, mbt1hfm_bx_p2, mbt1hfm_bx_p1, mbt1hfm_bx_0, mbt1hfm_bx_m1, mbt1hfm_bx_m2,
        mbt0hfp_data, mbt0hfp_bx_p2, mbt0hfp_bx_p1, mbt0hfp_bx_0, mbt0hfp_bx_m1, mbt0hfp_bx_m2,
        mbt0hfm_data, mbt0hfm_bx_p2, mbt0hfm_bx_p1, mbt0hfm_bx_0, mbt0hfm_bx_m1, mbt0hfm_bx_m2,
-- HB 2016-06-07: inserted new esums quantities (ETTEM and ETMHF).
        ettem_data, ettem_bx_p2, ettem_bx_p1, ettem_bx_0, ettem_bx_m1, ettem_bx_m2,
        etmhf_data, etmhf_bx_p2, etmhf_bx_p1, etmhf_bx_0, etmhf_bx_m1, etmhf_bx_m2,
-- HB 2016-09-16: inserted HTMHF and TOWERCNT
        htmhf_data, htmhf_bx_p2, htmhf_bx_p1, htmhf_bx_0, htmhf_bx_m1, htmhf_bx_m2,
        towercount_data, towercount_bx_p2, towercount_bx_p1, towercount_bx_0, towercount_bx_m1, towercount_bx_m2,
-- HB 2018-08-06: inserted "Asymmetry" and "Centrality"
        asymet_data, asymet_bx_p2, asymet_bx_p1, asymet_bx_0, asymet_bx_m1, asymet_bx_m2,
        asymht_data, asymht_bx_p2, asymht_bx_p1, asymht_bx_0, asymht_bx_m1, asymht_bx_m2,
        asymethf_data, asymethf_bx_p2, asymethf_bx_p1, asymethf_bx_0, asymethf_bx_m1, asymethf_bx_m2,
        asymhthf_data, asymhthf_bx_p2, asymhthf_bx_p1, asymhthf_bx_0, asymhthf_bx_m1, asymhthf_bx_m2,
        centrality_data, centrality_bx_p2_int, centrality_bx_p1_int, centrality_bx_0_int, centrality_bx_m1_int, centrality_bx_m2_int,
-- ****************************************************************************************
-- HB 2016-01-08: renamed ext_cond after +/-2bx to ext_cond_bx_p2_int, etc., because ext_cond_bx_p2, etc. used in algos (names coming from TME grammar).
        external_conditions, ext_cond_bx_p2_int, ext_cond_bx_p1_int, ext_cond_bx_0_int, ext_cond_bx_m1_int, ext_cond_bx_m2_int
    );

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- IMPORTANT COMMENT:
-- Processes for ext_cond_pipe_p and centrality_pipe_p not used, because HLS synthesis has latency = 0 (no intermediate registers!)
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

algos_i: entity work.algos_0
    port map(
        eg_bx_0(0)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(1)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(2)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(3)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(4)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(5)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(6)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(7)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(8)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(9)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(10)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(11)(EG_ET_HIGH downto EG_ET_LOW),
        eg_bx_0(0)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(1)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(2)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(3)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(4)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(5)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(6)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(7)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(8)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(9)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(10)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(11)(EG_ETA_HIGH downto EG_ETA_LOW),
        eg_bx_0(0)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(1)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(2)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(3)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(4)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(5)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(6)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(7)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(8)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(9)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(10)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(11)(EG_PHI_HIGH downto EG_PHI_LOW),
        eg_bx_0(0)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(1)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(2)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(3)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(4)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(5)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(6)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(7)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(8)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(9)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(10)(EG_ISO_HIGH downto EG_ISO_LOW),
        eg_bx_0(11)(EG_ISO_HIGH downto EG_ISO_LOW),

        jet_bx_0(0)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(1)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(2)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(3)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(4)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(5)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(6)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(7)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(8)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(9)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(10)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(11)(JET_ET_HIGH downto JET_ET_LOW),
        jet_bx_0(0)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(1)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(2)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(3)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(4)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(5)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(6)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(7)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(8)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(9)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(10)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(11)(JET_ETA_HIGH downto JET_ETA_LOW),
        jet_bx_0(0)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(1)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(2)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(3)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(4)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(5)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(6)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(7)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(8)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(9)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(10)(JET_PHI_HIGH downto JET_PHI_LOW),
        jet_bx_0(11)(JET_PHI_HIGH downto JET_PHI_LOW),

        tau_bx_0(0)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(1)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(2)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(3)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(4)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(5)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(6)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(7)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(8)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(9)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(10)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(11)(TAU_ET_HIGH downto TAU_ET_LOW),
        tau_bx_0(0)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(1)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(2)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(3)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(4)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(5)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(6)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(7)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(8)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(9)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(10)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(11)(TAU_ETA_HIGH downto TAU_ETA_LOW),
        tau_bx_0(0)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(1)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(2)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(3)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(4)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(5)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(6)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(7)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(8)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(9)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(10)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(11)(TAU_PHI_HIGH downto TAU_PHI_LOW),
        tau_bx_0(0)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(1)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(2)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(3)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(4)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(5)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(6)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(7)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(8)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(9)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(10)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        tau_bx_0(11)(TAU_ISO_HIGH downto TAU_ISO_LOW),
        
        muon_bx_0(0)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(1)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(2)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(3)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(4)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(5)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(6)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(7)(MUON_PHI_HIGH downto MUON_PHI_LOW),
        muon_bx_0(0)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(1)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(2)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(3)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(4)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(5)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(6)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(7)(MUON_PT_HIGH downto MUON_PT_LOW),
        muon_bx_0(0)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(1)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(2)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(3)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(4)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(5)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(6)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(7)(MUON_QUAL_HIGH downto MUON_QUAL_LOW),
        muon_bx_0(0)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(1)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(2)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(3)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(4)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(5)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(6)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(7)(MUON_ETA_HIGH downto MUON_ETA_LOW),
        muon_bx_0(0)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(1)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(2)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(3)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(4)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(5)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(6)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(7)(MUON_ISO_HIGH downto MUON_ISO_LOW),
        muon_bx_0(0)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(1)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(2)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(3)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(4)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(5)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(6)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        muon_bx_0(7)(MUON_CHARGE_HIGH downto MUON_CHARGE_LOW),
        
        asymet_bx_0(ASYMET_HIGH downto ASYMET_LOW),
        asymht_bx_0(ASYMHT_HIGH downto ASYMHT_LOW),
        asymethf_bx_0(ASYMETHF_HIGH downto ASYMETHF_LOW),
        asymhthf_bx_0(ASYMHTHF_HIGH downto ASYMHTHF_LOW),
        
        centrality_bx_0_int, -- no intermediate registers in HLS
        ext_cond_bx_0_int, -- no intermediate registers in HLS
        
        a_i(0), a_i(1), a_i(2), a_i(3), a_i(4), a_i(5), a_i(6), a_i(7), a_i(8), a_i(9), 
        a_i(10), a_i(11), a_i(12), a_i(13), a_i(14), a_i(15), a_i(16), a_i(17), a_i(18), a_i(19), 
        a_i(20), a_i(21), a_i(22), a_i(23), a_i(24), a_i(25), a_i(26), a_i(27), a_i(28), a_i(29), 
        a_i(30), a_i(31), a_i(32), a_i(33), a_i(34), a_i(35), a_i(36), a_i(37), a_i(38), a_i(39), 
        a_i(40), a_i(41), a_i(42), a_i(43), a_i(44), a_i(45), a_i(46), a_i(47), a_i(48), a_i(49), 
        a_i(50), a_i(51), a_i(52), a_i(53), a_i(54), a_i(55), a_i(56), a_i(57), a_i(58), a_i(59), 
        a_i(60), a_i(61), a_i(62), a_i(63), a_i(64), a_i(65), a_i(66), a_i(67), a_i(68), a_i(69), 
        a_i(70), a_i(71), a_i(72), a_i(73), a_i(74), a_i(75), a_i(76), a_i(77), a_i(78), a_i(79), 
        a_i(80), a_i(81), a_i(82), a_i(83), a_i(84), a_i(85), a_i(86), a_i(87), a_i(88), a_i(89), 
        a_i(90), a_i(91), a_i(92), a_i(93), a_i(94), a_i(95), a_i(96), a_i(97), a_i(98), a_i(99), 
        a_i(100), a_i(101), a_i(102), a_i(103), a_i(104), a_i(105), a_i(106), a_i(107), a_i(108), a_i(109), 
        a_i(110), a_i(111), a_i(112), a_i(113), a_i(114), a_i(115), a_i(116), a_i(117), a_i(118), a_i(119), 
        a_i(120), a_i(121), a_i(122), a_i(123), a_i(124), a_i(125), a_i(126), a_i(127), a_i(128), a_i(129), 
        a_i(130), a_i(131), a_i(132), a_i(133), a_i(134), a_i(135), a_i(136), a_i(137), a_i(138), a_i(139), 
        a_i(140), a_i(141), a_i(142), a_i(143), a_i(144), a_i(145), a_i(146), a_i(147), a_i(148), a_i(149), 
        a_i(150), a_i(151), a_i(152), a_i(153), a_i(154), a_i(155), a_i(156), a_i(157), a_i(158), a_i(159), 
        a_i(160), a_i(161), a_i(162), a_i(163), a_i(164), a_i(165), a_i(166), a_i(167), a_i(168), a_i(169), 
        a_i(170), a_i(171), a_i(172), a_i(173), a_i(174), a_i(175), a_i(176), a_i(177), a_i(178), a_i(179), 
        a_i(180), a_i(181), a_i(182), a_i(183), a_i(184), a_i(185), a_i(186), a_i(187), a_i(188), a_i(189), 
        a_i(190), a_i(191), a_i(192), a_i(193), a_i(194), a_i(195), a_i(196), a_i(197), a_i(198), a_i(199), 
        a_i(200), a_i(201), a_i(202), a_i(203), a_i(204), a_i(205), a_i(206), a_i(207), a_i(208), a_i(209), 
        a_i(210), a_i(211), a_i(212), a_i(213), a_i(214), a_i(215), a_i(216), a_i(217), a_i(218), a_i(219), 
        a_i(220), a_i(221), a_i(222), a_i(223), a_i(224), a_i(225), a_i(226), a_i(227), a_i(228), a_i(229), 
        a_i(230), a_i(231), a_i(232), a_i(233), a_i(234), a_i(235), a_i(236), a_i(237), a_i(238), a_i(239), 
        a_i(240), a_i(241), a_i(242), a_i(243), a_i(244), a_i(245), a_i(246), a_i(247), a_i(248), a_i(249), 
        a_i(250), a_i(251), a_i(252), a_i(253), a_i(254), a_i(255), a_i(256), a_i(257), a_i(258), a_i(259), 
        a_i(260), a_i(261), a_i(262), a_i(263), a_i(264), a_i(265), a_i(266), a_i(267), a_i(268), a_i(269), 
        a_i(270), a_i(271), a_i(272), a_i(273), a_i(274), a_i(275), a_i(276), a_i(277), a_i(278), a_i(279), 
        a_i(280), a_i(281), a_i(282), a_i(283), a_i(284), a_i(285), a_i(286), a_i(287), a_i(288), a_i(289), 
        a_i(290), a_i(291), a_i(292), a_i(293), a_i(294), a_i(295), a_i(296), a_i(297), a_i(298), a_i(299), 
        a_i(300), a_i(301), a_i(302), a_i(303), a_i(304), a_i(305), a_i(306), a_i(307), a_i(308), a_i(309), 
        a_i(310), a_i(311), a_i(312), a_i(313), a_i(314), a_i(315), a_i(316), a_i(317), a_i(318), a_i(319), 
        a_i(320), a_i(321), a_i(322), a_i(323), a_i(324), a_i(325), a_i(326), a_i(327), a_i(328), a_i(329), 
        a_i(330), a_i(331), a_i(332), a_i(333), a_i(334), a_i(335), a_i(336), a_i(337), a_i(338), a_i(339), 
        a_i(340), a_i(341), a_i(342), a_i(343), a_i(344), a_i(345), a_i(346), a_i(347), a_i(348), a_i(349), 
        a_i(350), a_i(351), a_i(352), a_i(353), a_i(354), a_i(355), a_i(356), a_i(357), a_i(358), a_i(359), 
        a_i(360), a_i(361), a_i(362), a_i(363), a_i(364), a_i(365), a_i(366), a_i(367), a_i(368), a_i(369), 
        a_i(370), a_i(371), a_i(372), a_i(373), a_i(374), a_i(375), a_i(376), a_i(377), a_i(378), a_i(379), 
        a_i(380), a_i(381), a_i(382), a_i(383), a_i(384), a_i(385), a_i(386), a_i(387), a_i(388), a_i(389), 
        a_i(390), a_i(391), a_i(392), a_i(393), a_i(394), a_i(395), a_i(396), a_i(397), a_i(398), a_i(399), 
        a_i(400), a_i(401), a_i(402), a_i(403), a_i(404), a_i(405), a_i(406), a_i(407), a_i(408), a_i(409), 
        a_i(410), a_i(411), a_i(412), a_i(413), a_i(414), a_i(415), a_i(416), a_i(417), a_i(418), a_i(419), 
        a_i(420), a_i(421), a_i(422), a_i(423), a_i(424), a_i(425), a_i(426), a_i(427), a_i(428), a_i(429), 
        a_i(430), a_i(431), a_i(432), a_i(433), a_i(434), a_i(435), a_i(436), a_i(437), a_i(438), a_i(439), 
        a_i(440), a_i(441), a_i(442), a_i(443), a_i(444), a_i(445), a_i(446), a_i(447), a_i(448), a_i(449), 
        a_i(450), a_i(451), a_i(452), a_i(453), a_i(454), a_i(455), a_i(456), a_i(457), a_i(458), a_i(459), 
        a_i(460), a_i(461), a_i(462), a_i(463), a_i(464), a_i(465), a_i(466), a_i(467), a_i(468), a_i(469), 
        a_i(470), a_i(471), a_i(472), a_i(473), a_i(474), a_i(475), a_i(476), a_i(477), a_i(478), a_i(479), 
        a_i(480), a_i(481), a_i(482), a_i(483), a_i(484), a_i(485), a_i(486), a_i(487), a_i(488), a_i(489), 
        a_i(490), a_i(491), a_i(492), a_i(493), a_i(494), a_i(495), a_i(496), a_i(497), a_i(498), a_i(499), 
        a_i(500), a_i(501), a_i(502), a_i(503), a_i(504), a_i(505), a_i(506), a_i(507), a_i(508), a_i(509), 
        a_i(510), a_i(511)
);

-- ========================================================

-- Conversion from array ofstd_logic_vector to std_logic_vector
algo_loop: for i in 0 to MAX_NR_ALGOS-1 generate
    a_i_1(i) <= a_i(i)(0);
end generate algo_loop;

-- Three pipeline stages for algorithms (no pipeline in HLS) - same latency as VHDL approach
algo_pipeline_p: process(lhc_clk, a_i_1)
    begin
    if (lhc_clk'event and lhc_clk = '1') then
        algo_int_1 <= a_i_1;
        algo_int_2 <= algo_int_1;
        algo_o <= algo_int_2;
    end if;
end process;

end architecture rtl;
