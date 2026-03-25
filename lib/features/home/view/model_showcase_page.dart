import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kBgColor = Color(0xFF0D1117);
const _kSurfaceColor = Color(0xFF161B22);
const _kCardColor = Color(0xFF1C2333);
const _kNeonGreen = Color(0xFF00F5A0);
const _kGold = Color(0xFFF5C518);
const _kCyberPurple = Color(0xFF7B2FFF);
const _kCyan = Color(0xFF00D9FF);

// ---------------------------------------------------------------------------
// Model definition
// ---------------------------------------------------------------------------

class _Model3D {
  const _Model3D({required this.name, required this.path, this.thumbnail});
  final String name;
  final String path;
  final String? thumbnail; // Optional thumbnail image path
}

class _ModelCategory {
  const _ModelCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.models,
  });
  final String label;
  final IconData icon;
  final Color color;
  final List<_Model3D> models;
}

// ---------------------------------------------------------------------------
// All categories
// ---------------------------------------------------------------------------

final List<_ModelCategory> _kCategories = [
  _ModelCategory(
    label: 'Characters',
    icon: Icons.person,
    color: _kNeonGreen,
    models: const [
      _Model3D(name: 'Knight', path: 'assets/3d/characters/Knight.glb', thumbnail: 'assets/sprites/3d_thumbnails/Knight.png'),
      _Model3D(name: 'Mage', path: 'assets/3d/characters/Mage.glb', thumbnail: 'assets/sprites/3d_thumbnails/Mage.png'),
      _Model3D(name: 'Ranger', path: 'assets/3d/characters/Ranger.glb', thumbnail: 'assets/sprites/3d_thumbnails/Ranger.png'),
      _Model3D(name: 'Barbarian', path: 'assets/3d/characters/Barbarian.glb', thumbnail: 'assets/sprites/3d_thumbnails/Barbarian.png'),
      _Model3D(name: 'Rogue', path: 'assets/3d/characters/Rogue.glb', thumbnail: 'assets/sprites/3d_thumbnails/Rogue.png'),
      _Model3D(name: 'Rogue Hooded', path: 'assets/3d/characters/Rogue_Hooded.glb', thumbnail: 'assets/sprites/3d_thumbnails/Rogue_Hooded.png'),
    ],
  ),
  _ModelCategory(
    label: 'Furniture',
    icon: Icons.chair,
    color: _kGold,
    models: const [
      _Model3D(name: 'Armchair', path: 'assets/3d/furniture/armchair.glb'),
      _Model3D(name: 'Armchair Pillows', path: 'assets/3d/furniture/armchair_pillows.glb'),
      _Model3D(name: 'Couch', path: 'assets/3d/furniture/couch.glb'),
      _Model3D(name: 'Couch Pillows', path: 'assets/3d/furniture/couch_pillows.glb'),
      _Model3D(name: 'Table Low', path: 'assets/3d/furniture/table_low.glb'),
      _Model3D(name: 'Table Medium', path: 'assets/3d/furniture/table_medium.glb'),
      _Model3D(name: 'Table Small', path: 'assets/3d/furniture/table_small.glb'),
      _Model3D(name: 'Table Long', path: 'assets/3d/furniture/table_medium_long.glb'),
      _Model3D(name: 'Chair A', path: 'assets/3d/furniture/chair_A.glb'),
      _Model3D(name: 'Chair B', path: 'assets/3d/furniture/chair_B.glb'),
      _Model3D(name: 'Chair C', path: 'assets/3d/furniture/chair_C.glb'),
      _Model3D(name: 'Chair Stool', path: 'assets/3d/furniture/chair_stool.glb'),
      _Model3D(name: 'Chair A Wood', path: 'assets/3d/furniture/chair_A_wood.glb'),
      _Model3D(name: 'Chair B Wood', path: 'assets/3d/furniture/chair_B_wood.glb'),
      _Model3D(name: 'Stool Wood', path: 'assets/3d/furniture/chair_stool_wood.glb'),
      _Model3D(name: 'Shelf A Big', path: 'assets/3d/furniture/shelf_A_big.glb'),
      _Model3D(name: 'Shelf A Small', path: 'assets/3d/furniture/shelf_A_small.glb'),
      _Model3D(name: 'Shelf B Large', path: 'assets/3d/furniture/shelf_B_large.glb'),
      _Model3D(name: 'Shelf B Decorated', path: 'assets/3d/furniture/shelf_B_large_decorated.glb'),
      _Model3D(name: 'Shelf B Small', path: 'assets/3d/furniture/shelf_B_small.glb'),
      _Model3D(name: 'Lamp Standing', path: 'assets/3d/furniture/lamp_standing.glb'),
      _Model3D(name: 'Lamp Table', path: 'assets/3d/furniture/lamp_table.glb'),
      _Model3D(name: 'Bed Double A', path: 'assets/3d/furniture/bed_double_A.glb'),
      _Model3D(name: 'Bed Double B', path: 'assets/3d/furniture/bed_double_B.glb'),
      _Model3D(name: 'Bed Single A', path: 'assets/3d/furniture/bed_single_A.glb'),
      _Model3D(name: 'Bed Single B', path: 'assets/3d/furniture/bed_single_B.glb'),
      _Model3D(name: 'Cabinet Medium', path: 'assets/3d/furniture/cabinet_medium.glb'),
      _Model3D(name: 'Cabinet Decorated', path: 'assets/3d/furniture/cabinet_medium_decorated.glb'),
      _Model3D(name: 'Cabinet Small', path: 'assets/3d/furniture/cabinet_small.glb'),
      _Model3D(name: 'Rug Oval A', path: 'assets/3d/furniture/rug_oval_A.glb'),
      _Model3D(name: 'Rug Oval B', path: 'assets/3d/furniture/rug_oval_B.glb'),
      _Model3D(name: 'Rug Rect A', path: 'assets/3d/furniture/rug_rectangle_A.glb'),
      _Model3D(name: 'Rug Rect B', path: 'assets/3d/furniture/rug_rectangle_B.glb'),
      _Model3D(name: 'Rug Stripes A', path: 'assets/3d/furniture/rug_rectangle_stripes_A.glb'),
      _Model3D(name: 'Book Set', path: 'assets/3d/furniture/book_set.glb'),
      _Model3D(name: 'Book Single', path: 'assets/3d/furniture/book_single.glb'),
      _Model3D(name: 'Cactus A', path: 'assets/3d/furniture/cactus_medium_A.glb'),
      _Model3D(name: 'Cactus B', path: 'assets/3d/furniture/cactus_medium_B.glb'),
      _Model3D(name: 'Picture Large A', path: 'assets/3d/furniture/pictureframe_large_A.glb'),
      _Model3D(name: 'Picture Large B', path: 'assets/3d/furniture/pictureframe_large_B.glb'),
      _Model3D(name: 'Pillow A', path: 'assets/3d/furniture/pillow_A.glb'),
      _Model3D(name: 'Pillow B', path: 'assets/3d/furniture/pillow_B.glb'),
    ],
  ),
  _ModelCategory(
    label: 'Resources',
    icon: Icons.diamond_outlined,
    color: _kCyberPurple,
    models: const [
      _Model3D(name: 'Gold Bar', path: 'assets/3d/resources/Gold_Bar.glb'),
      _Model3D(name: 'Gold Bars', path: 'assets/3d/resources/Gold_Bars.glb'),
      _Model3D(name: 'Gold Stack Large', path: 'assets/3d/resources/Gold_Bars_Stack_Large.glb'),
      _Model3D(name: 'Gold Nugget', path: 'assets/3d/resources/Gold_Nugget_Large.glb'),
      _Model3D(name: 'Silver Bar', path: 'assets/3d/resources/Silver_Bar.glb'),
      _Model3D(name: 'Silver Bars', path: 'assets/3d/resources/Silver_Bars.glb'),
      _Model3D(name: 'Copper Bar', path: 'assets/3d/resources/Copper_Bar.glb'),
      _Model3D(name: 'Copper Bars', path: 'assets/3d/resources/Copper_Bars.glb'),
      _Model3D(name: 'Iron Bar', path: 'assets/3d/resources/Iron_Bar.glb'),
      _Model3D(name: 'Iron Bars', path: 'assets/3d/resources/Iron_Bars.glb'),
      _Model3D(name: 'Fuel Barrel A', path: 'assets/3d/resources/Fuel_A_Barrel.glb'),
      _Model3D(name: 'Fuel Barrels A', path: 'assets/3d/resources/Fuel_A_Barrels.glb'),
      _Model3D(name: 'Wood Log A', path: 'assets/3d/resources/Wood_Log_A.glb'),
      _Model3D(name: 'Wood Plank A', path: 'assets/3d/resources/Wood_Plank_A.glb'),
      _Model3D(name: 'Stone Brick', path: 'assets/3d/resources/Stone_Brick.glb'),
      _Model3D(name: 'Textiles A', path: 'assets/3d/resources/Textiles_A.glb'),
      _Model3D(name: 'Parts Cog', path: 'assets/3d/resources/Parts_Cog.glb'),
    ],
  ),
  _ModelCategory(
    label: 'City',
    icon: Icons.location_city,
    color: _kCyan,
    models: const [
      _Model3D(name: 'Building A', path: 'assets/3d/city/building_A.glb'),
      _Model3D(name: 'Building B', path: 'assets/3d/city/building_B.glb'),
      _Model3D(name: 'Building C', path: 'assets/3d/city/building_C.glb'),
      _Model3D(name: 'Building D', path: 'assets/3d/city/building_D.glb'),
      _Model3D(name: 'Building E', path: 'assets/3d/city/building_E.glb'),
      _Model3D(name: 'Building F', path: 'assets/3d/city/building_F.glb'),
      _Model3D(name: 'Building G', path: 'assets/3d/city/building_G.glb'),
      _Model3D(name: 'Building H', path: 'assets/3d/city/building_H.glb'),
      _Model3D(name: 'Car Sedan', path: 'assets/3d/city/car_sedan.glb'),
      _Model3D(name: 'Car Taxi', path: 'assets/3d/city/car_taxi.glb'),
      _Model3D(name: 'Car Police', path: 'assets/3d/city/car_police.glb'),
      _Model3D(name: 'Car Hatchback', path: 'assets/3d/city/car_hatchback.glb'),
      _Model3D(name: 'Car Wagon', path: 'assets/3d/city/car_stationwagon.glb'),
      _Model3D(name: 'Road Straight', path: 'assets/3d/city/road_straight.glb'),
      _Model3D(name: 'Road Corner', path: 'assets/3d/city/road_corner.glb'),
      _Model3D(name: 'Road Junction', path: 'assets/3d/city/road_junction.glb'),
      _Model3D(name: 'Streetlight', path: 'assets/3d/city/streetlight.glb'),
      _Model3D(name: 'Traffic Light A', path: 'assets/3d/city/trafficlight_A.glb'),
      _Model3D(name: 'Bench', path: 'assets/3d/city/bench.glb'),
      _Model3D(name: 'Water Tower', path: 'assets/3d/city/watertower.glb'),
      _Model3D(name: 'Fire Hydrant', path: 'assets/3d/city/firehydrant.glb'),
    ],
  ),
  _ModelCategory(
    label: 'Forest',
    icon: Icons.park,
    color: const Color(0xFF4CAF50),
    models: const [
      _Model3D(name: 'Tree 1A', path: 'assets/3d/forest/Tree_1_A_Color1.glb'),
      _Model3D(name: 'Tree 1B', path: 'assets/3d/forest/Tree_1_B_Color1.glb'),
      _Model3D(name: 'Tree 2A', path: 'assets/3d/forest/Tree_2_A_Color1.glb'),
      _Model3D(name: 'Tree 3A', path: 'assets/3d/forest/Tree_3_A_Color1.glb'),
      _Model3D(name: 'Tree 4A', path: 'assets/3d/forest/Tree_4_A_Color1.glb'),
      _Model3D(name: 'Bush 1A', path: 'assets/3d/forest/Bush_1_A_Color1.glb'),
      _Model3D(name: 'Bush 2A', path: 'assets/3d/forest/Bush_2_A_Color1.glb'),
      _Model3D(name: 'Bush 3A', path: 'assets/3d/forest/Bush_3_A_Color1.glb'),
      _Model3D(name: 'Rock 1A', path: 'assets/3d/forest/Rock_1_A_Color1.glb'),
      _Model3D(name: 'Rock 2A', path: 'assets/3d/forest/Rock_2_A_Color1.glb'),
      _Model3D(name: 'Rock 3A', path: 'assets/3d/forest/Rock_3_A_Color1.glb'),
      _Model3D(name: 'Grass 1A', path: 'assets/3d/forest/Grass_1_A_Color1.glb'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// ModelShowcasePage
// ---------------------------------------------------------------------------

/// A gallery page showing ALL available 3D models organized by category.
/// Tapping a model opens a full-screen 3D viewer with rotation controls.
class ModelShowcasePage extends StatefulWidget {
  const ModelShowcasePage({super.key});

  static const String routeName = '/model-showcase';

  @override
  State<ModelShowcasePage> createState() => _ModelShowcasePageState();
}

class _ModelShowcasePageState extends State<ModelShowcasePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: _kSurfaceColor,
        foregroundColor: Colors.white,
        title: const Text(
          '3D Model Showcase',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _kNeonGreen,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabAlignment: TabAlignment.start,
          tabs: _kCategories
              .map(
                (cat) => Tab(
                  icon: Icon(cat.icon, size: 18),
                  text: cat.label,
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _kCategories
            .map((cat) => _CategoryGrid(category: cat))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoryGrid
// ---------------------------------------------------------------------------

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.category});

  final _ModelCategory category;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: category.models.length,
      itemBuilder: (context, index) {
        final model = category.models[index];
        return _ModelCard(
          model: model,
          color: category.color,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ModelCard
// ---------------------------------------------------------------------------

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model, required this.color});

  final _Model3D model;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenViewer(context),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 40 / 255),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Thumbnail or placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 12 / 255),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: model.thumbnail != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: Image.asset(
                          model.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.view_in_ar,
                              size: 48,
                              color: color.withValues(alpha: 120 / 255),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.view_in_ar,
                          size: 48,
                          color: color.withValues(alpha: 120 / 255),
                        ),
                      ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                model.name,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenModelViewer(
          model: model,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FullScreenModelViewer
// ---------------------------------------------------------------------------

class _FullScreenModelViewer extends StatelessWidget {
  const _FullScreenModelViewer({required this.model, required this.color});

  final _Model3D model;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: _kSurfaceColor,
        foregroundColor: Colors.white,
        title: Text(
          model.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          ModelViewer(
            src: model.path,
            alt: model.name,
            ar: false,
            autoRotate: true,
            autoRotateDelay: 0,
            cameraControls: true,
            backgroundColor: _kBgColor,
            exposure: 1.0,
          ),
          // Hint text at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kSurfaceColor.withValues(alpha: 200 / 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Drag to rotate  |  Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 180 / 255),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
