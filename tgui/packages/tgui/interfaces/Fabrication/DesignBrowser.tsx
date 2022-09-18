import { sortBy } from 'common/collections';
import { classes } from 'common/react';
import { InfernoNode } from 'inferno';
import { useSharedState } from '../../backend';
import { Stack, Section, Icon, Dimmer } from '../../components';
import { Design, MaterialMap } from './Types';
import { SearchBar } from './SearchBar';

/**
 * A function that does nothing.
 */
const NOOP = () => {};

export type DesignBrowserProps = {
  /**
   * All of the designs available to the browser.
   */
  designs: Design[];

  /**
   * A map of materials available for printing designs.
   */
  availableMaterials?: MaterialMap;

  /**
   * Invoked when the user attempts to print a design.
   */
  onPrintDesign?: (design: Design, amount: number) => void;

  /**
   * If present, dims out the recipe list with a "building items" animation.
   */
  busy?: boolean;

  /**
   * Invoked for every recipe visible in the design browser. Returns a single
   * row to be rendered to the output.
   */
  buildRecipeElement: (
    /**
     * The design being rendered.
     */
    design: Design,

    /**
     * The materials available to print the design.
     */
    availableMaterials: MaterialMap,

    /**
     * A callback to print the design.
     */
    onPrintDesign: (design: Design, amount: number) => void
  ) => InfernoNode;
};

/**
 * A meta-category that, when selected, renders all designs to the output.
 */
const ALL_CATEGORY = 'All Designs';

/**
 * A meta-category that collects all designs without a single category.
 */
const UNCATEGORIZED = '/Uncategorized';

/**
 * A single category in the category tree.
 */
type Category = {
  /**
   * The human-readable title of this category.
   */
  title: string;

  /**
   * The `id` of the `Section` rendering this category in the browser.
   */
  anchorKey: string;

  /**
   * All designs appearing in this category and its descendants.
   */
  descendants: Design[];

  /**
   * All designs within this specific category.
   */
  children: Design[];

  /**
   * The subcategories within this one, keyed by their titles.
   */
  subcategories: Record<string, Category>;
};

/**
 * Categories present in this object are not rendered to the final fabricator
 * UI.
 */
const BLACKLISTED_CATEGORIES: Record<string, boolean> = {
  'initial': true,
  'core': true,
  'hacked': true,
};

export const DesignBrowser = (props: DesignBrowserProps, context) => {
  const {
    designs,
    availableMaterials,
    onPrintDesign,
    buildRecipeElement,
    busy,
  } = props;

  const [selectedCategory, setSelectedCategory] = useSharedState(
    context,
    'selected_category',
    ALL_CATEGORY
  );

  const [searchText, setSearchText] = useSharedState(
    context,
    'search_text',
    ''
  );

  // Build a root category from the designs.
  const root: Category = {
    title: ALL_CATEGORY,
    anchorKey: ALL_CATEGORY.replace(/ /g, ''),
    descendants: [],
    children: [],
    subcategories: {},
  };

  // Sort every design into a single category in the tree.
  for (const design of designs) {
    // For designs without any categories, assign them to the "uncategorized"
    // category.
    const categories =
      design.categories.length === 0 ? [UNCATEGORIZED] : design.categories;

    for (const category of categories) {
      // If the category is a blacklisted meta-category, skip it entirely.
      if (BLACKLISTED_CATEGORIES[category]) {
        continue;
      }

      // Categories are slash-delimited.
      const nodes = category.split('/');

      // We always lead with a slash, so the first group is always empty.
      nodes.shift();

      // Find where this goes, and put it there.
      let parent = root;

      while (nodes.length > 0) {
        parent.descendants.push(design);

        const node = nodes.shift()!;

        if (!parent.subcategories[node]) {
          parent.subcategories[node] = {
            title: node,
            anchorKey: node.replace(/ /g, ''),
            descendants: [],
            children: [],
            subcategories: {},
          };
        }

        parent = parent.subcategories[node]!;
      }

      // This is our leaf.
      parent.descendants.push(design);
      parent.children.push(design);
    }
  }

  return (
    <Stack fill>
      {/* Left Column */}
      <Stack.Item width={'200px'}>
        <Section fill>
          <Stack vertical fill>
            <Stack.Item>
              <Section title="Categories" fitted />
            </Stack.Item>
            <Stack.Item grow>
              <Section fill style={{ 'overflow': 'auto' }}>
                <div className="FabricatorTabs">
                  <div
                    className={classes([
                      'FabricatorTabs__Tab',
                      selectedCategory === ALL_CATEGORY &&
                        'FabricatorTabs__Tab--active',
                    ])}
                    onClick={() => setSelectedCategory(ALL_CATEGORY)}>
                    <div className="FabricatorTabs__Label">
                      <div className="FabricatorTabs__CategoryName">
                        All Designs
                      </div>
                      <div className="FabricatorTabs__CategoryCount">
                        ({root.descendants.length})
                      </div>
                    </div>
                  </div>

                  {sortBy((category: Category) => category.title)(
                    Object.values(root.subcategories)
                  ).map((category) => (
                    <DesignBrowserTab
                      key={category.title}
                      category={category}
                      selectedCategory={selectedCategory}
                      setSelectedCategory={setSelectedCategory}
                    />
                  ))}
                </div>
              </Section>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* Right Column */}
      <Stack.Item grow>
        <Section
          title={
            selectedCategory === ALL_CATEGORY ? 'All Designs' : selectedCategory
          }
          fill>
          <Stack vertical fill>
            <Stack.Item>
              <Section>
                <SearchBar
                  searchText={searchText}
                  onSearchTextChanged={setSearchText}
                  hint={'Search all designs...'}
                />
              </Section>
            </Stack.Item>
            <Stack.Item grow>
              <Section fill style={{ 'overflow': 'auto' }}>
                {searchText.length > 0 ? (
                  sortBy((design: Design) => design.name)(root.descendants)
                    .filter((design) =>
                      design.name
                        .toLocaleLowerCase()
                        .includes(searchText.toLowerCase())
                    )
                    .map((design) =>
                      buildRecipeElement(
                        design,
                        availableMaterials || {},
                        onPrintDesign || NOOP
                      )
                    )
                ) : selectedCategory === ALL_CATEGORY ? (
                  <CategoryView
                    category={root}
                    availableMaterials={availableMaterials}
                    onPrintDesign={onPrintDesign}
                    buildRecipeElement={buildRecipeElement}
                  />
                ) : (
                  root.subcategories[selectedCategory] && (
                    <CategoryView
                      category={root.subcategories[selectedCategory]}
                      availableMaterials={availableMaterials}
                      onPrintDesign={onPrintDesign}
                      buildRecipeElement={buildRecipeElement}
                    />
                  )
                )}
              </Section>
            </Stack.Item>
            {!!busy && (
              <Dimmer
                style={{
                  'font-size': '2em',
                  'text-align': 'center',
                }}>
                <Icon name="cog" spin />
                {' Building items...'}
              </Dimmer>
            )}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

type DesignBrowserTabProps = {
  category: Category;
  depth?: number;
  maxDepth?: number;
  selectedCategory: string;
  setSelectedCategory: (newCategory: string) => void;
};

const DesignBrowserTab = (props: DesignBrowserTabProps, context) => {
  let { category, depth, maxDepth, selectedCategory, setSelectedCategory } =
    props;

  depth ??= 0;
  maxDepth ??= 3;

  return (
    <div
      className={classes([
        'FabricatorTabs__Tab',
        /** Only highlight top-level categories. */
        depth === 0 &&
          selectedCategory === category.title &&
          'FabricatorTabs__Tab--active',
      ])}
      onClick={
        depth === 0
          ? /* For top-level categories, set the selected category. */
          () => setSelectedCategory(category.title)
          : /* For deeper categories, scroll the subcategory header into view. */
          () => {
            document.getElementById(category.anchorKey)?.scrollIntoView(true);
          }
      }>
      <div className="FabricatorTabs__Label">
        <div className="FabricatorTabs__CategoryName">{category.title}</div>
        {depth === 0 && (
          /** Show recipe counts on top-level categories. */
          <div className={'FabricatorTabs__CategoryCount'}>
            ({category.descendants.length})
          </div>
        )}
      </div>
      {depth < maxDepth &&
        Object.entries(category.subcategories).length > 0 &&
        selectedCategory === category.title && (
          <div className="FabricatorTabs">
            {sortBy((category: Category) => category.title)(
              Object.values(category.subcategories)
            ).map((subcategory) => (
              <DesignBrowserTab
                key={subcategory.title}
                category={subcategory}
                depth={(depth || 0) + 1}
                maxDepth={maxDepth}
                selectedCategory={selectedCategory}
                setSelectedCategory={setSelectedCategory}
              />
            ))}
          </div>
        )}
    </div>
  );
};

type CategoryViewProps = {
  /**
   * The category being rendered.
   */
  category: Category;

  /**
   * A map of materials available for printing designs.
   */
  availableMaterials?: MaterialMap;

  /**
   * The depth of this category in the view.
   */
  depth?: number;

  /**
   * Invoked when the user attempts to print a design.
   */
  onPrintDesign?: (design: Design, amount: number) => void;

  /**
   * Invoked for every recipe visible in the design browser. Returns a single
   * row to be rendered to the output.
   */
  buildRecipeElement: (
    /**
     * The design being rendered.
     */
    design: Design,

    /**
     * The materials available to print the design.
     */
    availableMaterials: MaterialMap,

    /**
     * A callback to print the design.
     */
    onPrintDesign: (design: Design, amount: number) => void
  ) => InfernoNode;
};

const CategoryView = (props: CategoryViewProps, context) => {
  let {
    depth,
    category,
    availableMaterials,
    onPrintDesign,
    buildRecipeElement,
  } = props;

  depth ??= 0;

  const body = (
    <>
      {sortBy((design: Design) => design.name)(category.children).map(
        (design) =>
          buildRecipeElement(
            design,
            availableMaterials || {},
            onPrintDesign || NOOP
          )
      )}

      {Object.keys(category.subcategories)
        .sort()
        .map((categoryName: string) => category.subcategories[categoryName])
        .map((category) => (
          <CategoryView
            {...props}
            depth={(depth || 0) + 1}
            category={category}
            key={category.title}
          />
        ))}
    </>
  );

  if (depth === 0) {
    return body;
  }

  return (
    <Section title={category.title} id={category.anchorKey}>
      {body}
    </Section>
  );
};
