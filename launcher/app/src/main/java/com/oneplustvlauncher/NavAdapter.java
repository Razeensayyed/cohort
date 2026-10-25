package com.oneplustvlauncher;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.oneplustvlauncher.utils.AppInfo;

import java.util.List;

public class NavAdapter extends RecyclerView.Adapter<NavAdapter.VH> {

    public interface OnClickListener { void onNavClicked(AppInfo app); }
    public interface OnFocusListener { void onNavFocused(boolean hasFocus); }

    private final List<AppInfo> mApps;
    private OnClickListener mClickListener;
    private OnFocusListener mFocusListener;

    public NavAdapter(List<AppInfo> apps) { this.mApps = apps; }
    public void setClickListener(OnClickListener l) { mClickListener = l; }
    public void setFocusListener(OnFocusListener l) { mFocusListener = l; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_nav_tile, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        AppInfo app = mApps.get(position);
        holder.icon.setImageDrawable(app.icon);
        holder.name.setText(app.label);

        holder.itemView.setOnFocusChangeListener((v, hasFocus) -> {
            holder.itemView.animate()
                    .scaleX(hasFocus ? 1.15f : 1f)
                    .scaleY(hasFocus ? 1.15f : 1f)
                    .setDuration(130).start();
            holder.itemView.setBackgroundResource(
                    hasFocus ? R.drawable.bg_pill_focused : R.drawable.bg_pill);
            if (mFocusListener != null) mFocusListener.onNavFocused(hasFocus);
        });

        holder.itemView.setOnClickListener(v -> {
            if (mClickListener != null) mClickListener.onNavClicked(app);
        });
    }

    @Override public int getItemCount() { return mApps.size(); }

    static class VH extends RecyclerView.ViewHolder {
        ImageView icon;
        TextView name;
        VH(@NonNull View v) {
            super(v);
            icon = v.findViewById(R.id.app_icon);
            name = v.findViewById(R.id.app_name);
        }
    }
}
