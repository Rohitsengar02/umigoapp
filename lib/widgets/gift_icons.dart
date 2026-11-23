import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _p = '#CF3F6C', _a = '#FF9F80';

const _giftSvgs = <String, String>{
  'rose': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path d="M24 26v18" stroke="#2E9E5B" stroke-width="3" stroke-linecap="round"/><path d="M24 36c-6-1-9-5-9-5 5-1 8 1 9 5Z" fill="#2E9E5B"/><circle cx="24" cy="16" r="11" fill="#E8204E"/><path d="M17 15c3-6 11-6 14 0-3 3-11 3-14 0Z" fill="#B5133A"/><circle cx="24" cy="15" r="3.5" fill="#8C0E2C"/></svg>',
  'heart':
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 21 4.6 13.6A5 5 0 0 1 12 6.5a5 5 0 0 1 7.4 7.1z" fill="$_p"/><ellipse cx="8.5" cy="10" rx="1.8" ry="1.1" fill="#FFFFFF" opacity=".6"/></svg>',
  'coffee': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path d="M10 18h24v12a10 10 0 0 1-10 10h-4a10 10 0 0 1-10-10Z" fill="#8D5A3B"/><path d="M34 21h3a5 5 0 0 1 0 10h-3" stroke="#8D5A3B" stroke-width="3" fill="none"/><rect x="10" y="16" width="24" height="5" rx="2.5" fill="#F3D9C2"/><path d="M18 6c-2 3 2 4 0 7M24 6c-2 3 2 4 0 7" stroke="#C4A48E" stroke-width="2" stroke-linecap="round" fill="none"/></svg>',
  'star': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2l3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8l-6.2 3.2L7 14.1 2 9.3l6.9-1z" fill="#FFB800"/><path d="M12 6l1.6 3.4 3.6.5" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity=".7"/></svg>',
  'crown':
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="m2 6 3.5 11h13L22 6l-6 5.5-4-7-4 7Z" fill="#FFB800"/><rect x="5" y="18" width="14" height="3" rx="1" fill="#E09A00"/><circle cx="12" cy="13" r="1.6" fill="$_p"/></svg>',
  'rocket':
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 15l-3-3a22 22 0 0 1 2-4A12.9 12.9 0 0 1 22 2c0 2.7-.8 7.5-6 11a22.4 22.4 0 0 1-4 2z" fill="$_a"/><path d="M9 12H4s.6-3 2-4c1.6-1.1 5 0 5 0M12 15v5s3-.6 4-2c1.1-1.6 0-5 0-5" fill="$_p"/><circle cx="16" cy="8" r="1.8" fill="#FFFFFF"/><path d="M4.5 16.5c-1.5 1.3-2 5-2 5s3.7-.5 5-2c.7-.8.7-2.1-.1-2.9a2.2 2.2 0 0 0-2.9-.1z" fill="#FFB800"/></svg>',
  'ring': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="31" r="12" fill="none" stroke="#FFB800" stroke-width="4"/><path d="M16 10h16l4 6-12 10-12-10Z" fill="#7FD4FF"/><path d="M16 10l8 16 8-16M12 16h24" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity=".8"/></svg>',
  'car':
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path d="M4 30c0-3 2-5 5-6l6-6c2-2 4-3 7-3h8c3 0 5 1 7 3l5 6c3 1 4 3 4 6v4H4Z" fill="$_p"/><path d="M17 19h8v6H12Zm11 0h4l5 6h-9Z" fill="#CFE8FF"/><circle cx="13" cy="34" r="5" fill="#15131C"/><circle cx="35" cy="34" r="5" fill="#15131C"/><circle cx="13" cy="34" r="2" fill="#C0C6D0"/><circle cx="35" cy="34" r="2" fill="#C0C6D0"/></svg>',
};

class GiftIcon extends StatelessWidget {
  final String id;
  final double size;
  const GiftIcon(this.id, {super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => SvgPicture.string(_giftSvgs[id] ?? _giftSvgs['rose']!, width: size, height: size);
}
