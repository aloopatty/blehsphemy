import 'dart:ui';
import 'package:material_ui/material_ui.dart';

class Glass extends StatelessWidget {
  const Glass({super.key,required this.child,this.padding,this.radius=22,this.opacity=.075,this.border=true});
  final Widget child;
  final EdgeInsets? padding;
  final double radius,opacity;
  final bool border;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX:18,sigmaY:18),
        child: Container(
          padding:padding,
          decoration:BoxDecoration(
            color:Colors.white.withValues(alpha:opacity),
            borderRadius:BorderRadius.circular(radius),
            border:border ? Border.all(color:Colors.white.withValues(alpha:.12),width:.5) : null,
          ),
          child:child,
        ),
      ),
    );
  }
}
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key,required this.child,this.accent=const Color(0xFF6957D8),this.secondary=const Color(0xFF145B88)});
  final Widget child;
  final Color accent,secondary;
  @override
  Widget build(BuildContext context) {
    return Stack(children:[
      const Positioned.fill(child:ColoredBox(color:Color(0xFF08090E))),
      Positioned(top:-130,left:-90,child:_orb(accent,340)),
      Positioned(top:260,right:-170,child:_orb(secondary,330)),
      Positioned(bottom:-180,left:80,child:_orb(const Color(0xFF9A416E),280)),
      Positioned.fill(child:child),
    ]);
  }
  Widget _orb(Color color,double size)=>Container(width:size,height:size,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[color.withValues(alpha:.24),color.withValues(alpha:0)])));
}