-- CraftingOrderClassic_Elemental.lua — pseudo-« métier » de récolte « Élémentaire ».
--
-- Les marchandises élémentaires (eau/feu/terre/air : essences, motes, primals, cristallisés,
-- éternels) ne sont PAS récoltées par un métier : elles tombent des mobs élémentaires / sont
-- farmées. On les expose quand même dans l'onglet Récolte comme un faux métier pour pouvoir
-- en commander. Données côté ADDON (pas dans CraftLink) car ce n'est pas une vraie profession.
--
-- exp : extension qui introduit l'objet — 1 = Classic, 2 = TBC, 3 = WotLK. Combiné au filtre
-- d'existence client (GetItemInfoInstant), un client n'affiche QUE ce qu'il connaît ; le sélecteur
-- de version permet en plus de restreindre à une extension précise (utile sur TBC/WotLK).

local COC = CraftingOrderClassic

COC.Elemental = {
    { id = 7081  , exp = 1 },  -- Breath of Wind
    { id = 7075  , exp = 1 },  -- Core of Earth
    { id = 7069  , exp = 1 },  -- Elemental Air
    { id = 7067  , exp = 1 },  -- Elemental Earth
    { id = 7068  , exp = 1 },  -- Elemental Fire
    { id = 7070  , exp = 1 },  -- Elemental Water
    { id = 7082  , exp = 1 },  -- Essence of Air
    { id = 7076  , exp = 1 },  -- Essence of Earth
    { id = 7078  , exp = 1 },  -- Essence of Fire
    { id = 12808 , exp = 1 },  -- Essence of Undeath
    { id = 7080  , exp = 1 },  -- Essence of Water
    { id = 7079  , exp = 1 },  -- Globe of Water
    { id = 7077  , exp = 1 },  -- Heart of Fire
    { id = 10286 , exp = 1 },  -- Heart of the Wild
    { id = 7972  , exp = 1 },  -- Ichor of Undeath
    { id = 12803 , exp = 1 },  -- Living Essence
    { id = 22572 , exp = 2 },  -- Mote of Air
    { id = 22573 , exp = 2 },  -- Mote of Earth
    { id = 22574 , exp = 2 },  -- Mote of Fire
    { id = 22575 , exp = 2 },  -- Mote of Life
    { id = 22576 , exp = 2 },  -- Mote of Mana
    { id = 22577 , exp = 2 },  -- Mote of Shadow
    { id = 22578 , exp = 2 },  -- Mote of Water
    { id = 22451 , exp = 2 },  -- Primal Air
    { id = 22452 , exp = 2 },  -- Primal Earth
    { id = 21884 , exp = 2 },  -- Primal Fire
    { id = 21886 , exp = 2 },  -- Primal Life
    { id = 22457 , exp = 2 },  -- Primal Mana
    { id = 23571 , exp = 2 },  -- Primal Might
    { id = 22456 , exp = 2 },  -- Primal Shadow
    { id = 21885 , exp = 2 },  -- Primal Water
    { id = 37700 , exp = 3 },  -- Crystallized Air
    { id = 37701 , exp = 3 },  -- Crystallized Earth
    { id = 37702 , exp = 3 },  -- Crystallized Fire
    { id = 37704 , exp = 3 },  -- Crystallized Life
    { id = 37703 , exp = 3 },  -- Crystallized Shadow
    { id = 37705 , exp = 3 },  -- Crystallized Water
    { id = 35623 , exp = 3 },  -- Eternal Air
    { id = 35624 , exp = 3 },  -- Eternal Earth
    { id = 36860 , exp = 3 },  -- Eternal Fire
    { id = 35625 , exp = 3 },  -- Eternal Life
    { id = 40248 , exp = 3 },  -- Eternal Might
    { id = 35621 , exp = 3 },  -- Eternal Power
    { id = 35627 , exp = 3 },  -- Eternal Shadow
    { id = 35622 , exp = 3 },  -- Eternal Water
    { id = 34055 , exp = 3 },  -- Greater Cosmic Essence
}
