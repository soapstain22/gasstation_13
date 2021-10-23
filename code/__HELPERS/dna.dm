//////////////////////////////////////////////////////////
//A bunch of helpers to make genetics less of a headache//
//////////////////////////////////////////////////////////

#define GET_INITIALIZED_MUTATION(A) GLOB.all_mutations[A]
#define GET_GENE_STRING(A, B) (B.mutation_index[A])
#define GET_SEQUENCE(A) (GLOB.full_sequences[A])
#define GET_MUTATION_TYPE_FROM_ALIAS(A) (GLOB.alias_mutations[A])

#define GET_MUTATION_STABILIZER(A) ((A.stabilizer_coeff < 0) ? 1 : A.stabilizer_coeff)
#define GET_MUTATION_SYNCHRONIZER(A) ((A.synchronizer_coeff < 0) ? 1 : A.synchronizer_coeff)
#define GET_MUTATION_POWER(A) ((A.power_coeff < 0) ? 1 : A.power_coeff)
#define GET_MUTATION_ENERGY(A) ((A.energy_coeff < 0) ? 1 : A.energy_coeff)

#define GET_DNA_BLOCK(input, blocknum, len_by_block) copytext(input, len_by_block[blocknum], LAZYACCESS(len_by_block, blocknum+1))

#define GET_UI_BLOCK(input, blocknum) GET_DNA_BLOCK(input, blocknum, GLOB.total_ui_len_by_block)
#define GET_UF_BLOCK(input, blocknum) GET_DNA_BLOCK(input, blocknum, GLOB.total_uf_len_by_block)

///Getter macro used to get the length of a identity block
#define GET_UI_BLOCK_LEN(blocknum) (GLOB.identity_block_lengths["[blocknum]"] || DNA_BLOCK_SIZE)
///Ditto, but for a feature.
#define GET_UF_BLOCK_LEN(blocknum) (GLOB.features_block_lengths["[blocknum]"] || DNA_BLOCK_SIZE)
